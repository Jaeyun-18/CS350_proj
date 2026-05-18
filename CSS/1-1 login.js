/**
 * from Paper
 * https://app.paper.design/file/01KKB45NHWNEPMVKXMKFAHGMG7/01KN1RYDZNKGNXYJXY9E10RNX0/QN-0
 * on May 18, 2026
 */
export default function () {
  return (
    <div className="[font-synthesis:none] grow shrink basis-[0%] flex flex-col pb-9 overflow-clip antialiased text-xs/4 px-7">
      <div className="mt-11 mb-12">
        <div className="flex items-center mb-2.5 gap-3">
          <div className="w-12.5 h-12.5 flex items-center justify-center shrink-0 rounded-2xl" style={{ backgroundImage: 'linear-gradient(in oklab 140deg, oklab(80% -0.160 0.086) 0%, oklab(62.7% -0.146 0.087) 100%)' }}>
            <svg width="28" height="28" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ flexShrink: '0' }}>
              <circle cx="8" cy="8" r="3.5" fill="#FFFFFF" />
              <circle cx="20" cy="20" r="3.5" fill="#FFFFFF" />
              <line x1="5" y1="23" x2="23" y2="5" stroke="#FFFFFF" strokeWidth="2.8" strokeLinecap="round" />
            </svg>
          </div>
          <div className="[letter-spacing:-2px] inline-block font-['Inter',system-ui,sans-serif] font-extrabold text-[#0F172A] text-4xl/11">
            divvy
          </div>
        </div>
        <div className="text-[16px] leading-[150%] font-['Inter',system-ui,sans-serif] text-[#64748B] m-0">
          Split grocery runs. Save more together.
        </div>
      </div>
      <div className="mb-3.5">
        <div className="mb-2 tracking-[1px] font-['Inter',system-ui,sans-serif] font-bold text-[#94A3B8] text-[11px]/3.5">
          EMAIL
        </div>
        <div className="h-14 flex items-center rounded-[14px] px-4.5 gap-3 bg-[#F8FAFC] [border-width:1.5px] border-solid border-[#E2E8F0]">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" xmlns="http://www.w3.org/2000/svg" style={{ flexShrink: '0' }}>
            <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
            <polyline points="22,6 12,13 2,6" />
          </svg>
          <div className="inline-block font-['Inter',system-ui,sans-serif] text-[#94A3B8] text-[15px]/4.5">
            you@example.com
          </div>
        </div>
      </div>
      <div className="mb-2.5">
        <div className="mb-2 tracking-[1px] font-['Inter',system-ui,sans-serif] font-bold text-[#94A3B8] text-[11px]/3.5">
          PASSWORD
        </div>
        <div className="h-14 flex items-center justify-between rounded-[14px] px-4.5 gap-3 bg-[#F8FAFC] [border-width:1.5px] border-solid border-[#E2E8F0]">
          <div className="flex items-center gap-3">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" xmlns="http://www.w3.org/2000/svg" style={{ flexShrink: '0' }}>
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <div className="text-[20px] tracking-[4px] leading-[100%] inline-block font-['Inter',system-ui,sans-serif] text-[#94A3B8]">
              ••••••••
            </div>
          </div>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#CBD5E1" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" xmlns="http://www.w3.org/2000/svg" style={{ flexShrink: '0' }}>
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
            <circle cx="12" cy="12" r="3" />
          </svg>
        </div>
      </div>
      <div className="text-right mb-7 font-['Inter',system-ui,sans-serif] text-black text-base/5">
        Forgot password?
      </div>
      <div className="h-14.5 flex items-center justify-center mb-6 rounded-2xl shrink-0" style={{ backgroundImage: 'linear-gradient(in oklab 135deg, oklab(72.3% -0.166 0.097) 0%, oklab(62.7% -0.146 0.087) 100%)' }}>
        <div className="tracking-[0.3px] inline-block font-['Inter',system-ui,sans-serif] font-bold text-white text-base/5">
          Log In
        </div>
      </div>
      <div className="flex items-center mb-5 gap-3.5">
        <div className="grow shrink basis-[0%] h-px bg-[#E2E8F0]" />
        <div className="[white-space-collapse:collapse] inline-block w-max shrink-0 font-['Inter',system-ui,sans-serif] font-medium text-[#94A3B8] text-xs/4">
          or
        </div>
        <div className="grow shrink basis-[0%] h-px bg-[#E2E8F0]" />
      </div>
      <div className="flex items-center justify-center gap-1.25">
        <div className="inline-block font-['Inter',system-ui,sans-serif] text-[#94A3B8] text-sm/4.5">
          New to Divvy?
        </div>
        <div className="inline-block font-['Inter',system-ui,sans-serif] font-bold text-[#22C55E] text-sm/4.5">
          Create account →
        </div>
      </div>
    </div>
  );
}
