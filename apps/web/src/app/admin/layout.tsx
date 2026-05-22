import Link from "next/link";

export default function AdminLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="min-h-screen bg-zinc-50">
      <header className="border-b border-zinc-200 bg-white">
        <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-4 py-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-emerald-700">
              EcoWallet
            </p>
            <h1 className="text-lg font-semibold text-zinc-900">Backoffice</h1>
          </div>
          <nav className="flex gap-3 text-sm font-medium">
            <Link
              href="/admin/verificacao"
              className="font-semibold text-zinc-900 hover:text-emerald-800"
            >
              Verificação
            </Link>
            <Link
              href="/admin/auditoria"
              className="font-semibold text-zinc-900 hover:text-emerald-800"
            >
              Auditoria
            </Link>
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-5xl px-4 py-8">{children}</main>
    </div>
  );
}
