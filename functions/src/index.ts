/**
 * WeBuyDivvy Cloud Functions
 *
 * 그룹 채팅에 새 사용자 메시지가 생성되면 같은 그룹의 다른 멤버들에게 FCM
 * 푸시 알림을 발송한다. 시스템 메시지(참여/이탈 안내)는 알림 대상에서
 * 제외한다. 발송 응답에서 만료/무효 토큰이 보고되면 해당 사용자의
 * `fcmTokens` 배열에서 정리한다.
 */

import { initializeApp } from "firebase-admin/app";
import {
  DocumentReference,
  DocumentSnapshot,
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

interface ChatMessageDoc {
  text?: string;
  senderId?: string;
  senderName?: string;
  type?: string;
}

export const onChatMessage = onDocumentCreated(
  "group/{groupId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data() as ChatMessageDoc | undefined;
    if (!message || message.type !== "user") return;

    const text = (message.text ?? "").trim();
    if (text.length === 0) return;

    const { groupId } = event.params;
    const groupSnap = await db.doc(`group/${groupId}`).get();
    if (!groupSnap.exists) return;

    const senderId = message.senderId ?? "";
    if (senderId.length === 0) return; // 작성자 식별 불가하면 발송 보류.

    const memberIds =
      (groupSnap.get("member_ids") as string[] | undefined) ?? [];
    const targets = memberIds.filter((id) => id !== senderId);
    if (targets.length === 0) return;

    const userRefs: DocumentReference[] = targets.map((id) =>
      db.doc(`users/${id}`),
    );
    const userSnaps = await db.getAll(...userRefs);
    const tokenIndex: { token: string; snap: DocumentSnapshot }[] = [];
    for (const snap of userSnaps) {
      const tokens =
        (snap.get("fcmTokens") as string[] | undefined) ?? [];
      for (const token of tokens) {
        tokenIndex.push({ token, snap });
      }
    }
    if (tokenIndex.length === 0) return;

    const title =
      (groupSnap.get("name") as string | undefined) ?? "새 메시지";
    const senderName = message.senderName ?? "";
    const body = senderName ? `${senderName}: ${text}` : text;

    const response = await messaging.sendEachForMulticast({
      tokens: tokenIndex.map((entry) => entry.token),
      notification: { title, body },
      data: { groupId, type: "chat" },
    });

    logger.info(
      `chat push: ${response.successCount}/${tokenIndex.length} delivered`,
    );

    await cleanupInvalidTokens(tokenIndex, response.responses);
  },
);

async function cleanupInvalidTokens(
  tokenIndex: { token: string; snap: DocumentSnapshot }[],
  responses: { success: boolean; error?: { code?: string } }[],
): Promise<void> {
  // 동시 토큰 갱신과 경합해도 새 토큰을 잃지 않도록 사용자별로
  // arrayRemove를 사용한다(배열 전체 덮어쓰기 X).
  const invalidByRef = new Map<DocumentReference, Set<string>>();
  responses.forEach((resp, i) => {
    if (resp.success) return;
    const code = resp.error?.code ?? "";
    if (
      code !== "messaging/registration-token-not-registered" &&
      code !== "messaging/invalid-registration-token"
    ) {
      return;
    }
    const { token, snap } = tokenIndex[i];
    const set = invalidByRef.get(snap.ref) ?? new Set<string>();
    set.add(token);
    invalidByRef.set(snap.ref, set);
  });
  if (invalidByRef.size === 0) return;

  await Promise.all(
    Array.from(invalidByRef.entries()).map(([ref, invalid]) =>
      ref.update({
        fcmTokens: FieldValue.arrayRemove(...Array.from(invalid)),
      }),
    ),
  );
}
