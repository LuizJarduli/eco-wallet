import { domainErrorMessages } from "@/features/admin-disposals/constants";

interface ApiErrorBannerProps {
  code?: string;
  message?: string;
}

export const ApiErrorBanner = ({ code, message }: ApiErrorBannerProps) => {
  if (!code && !message) {
    return null;
  }

  const displayMessage =
    (code && domainErrorMessages[code]) ?? message ?? "Ocorreu um erro inesperado.";

  return (
    <div
      role="alert"
      className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"
    >
      {displayMessage}
    </div>
  );
};
