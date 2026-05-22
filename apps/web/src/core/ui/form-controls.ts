/** Shared admin form styles — see DESIGN.md § Eco Wallet Admin UI contrast. */

export const formLabelClassName = "text-sm font-semibold text-zinc-900";

export const formFieldClassName =
  "rounded-md border-2 border-zinc-600 bg-white px-3 py-2 text-sm font-medium text-zinc-900 shadow-sm placeholder:text-zinc-500 focus:border-emerald-800 focus:outline-none focus:ring-2 focus:ring-emerald-800/30 disabled:cursor-not-allowed disabled:border-zinc-400 disabled:bg-zinc-100 disabled:text-zinc-500";

export const formTextareaClassName = `${formFieldClassName} min-h-20 resize-y`;

export const buttonSecondaryClassName =
  "rounded-md border-2 border-zinc-700 bg-white px-3 py-2 text-sm font-semibold text-zinc-900 shadow-sm hover:bg-zinc-100 active:bg-zinc-200 focus:outline-none focus:ring-2 focus:ring-zinc-700/40 disabled:cursor-not-allowed disabled:border-zinc-400 disabled:text-zinc-500 disabled:shadow-none";

export const buttonPrimaryClassName =
  "rounded-md border-2 border-zinc-900 bg-zinc-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-800 active:bg-zinc-950 focus:outline-none focus:ring-2 focus:ring-zinc-900/40 disabled:cursor-not-allowed disabled:border-zinc-400 disabled:bg-zinc-400 disabled:text-zinc-100";

export const buttonSuccessClassName =
  "rounded-md border-2 border-emerald-800 bg-emerald-800 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-emerald-900 active:bg-emerald-950 focus:outline-none focus:ring-2 focus:ring-emerald-800/40 disabled:cursor-not-allowed disabled:border-emerald-300 disabled:bg-emerald-200 disabled:text-emerald-900";

export const buttonDangerClassName =
  "rounded-md border-2 border-red-800 bg-red-800 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-900 active:bg-red-950 focus:outline-none focus:ring-2 focus:ring-red-800/40 disabled:cursor-not-allowed disabled:border-red-300 disabled:bg-red-200 disabled:text-red-900";
