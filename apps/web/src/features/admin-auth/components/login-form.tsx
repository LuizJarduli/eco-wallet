"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import { createSupabaseBrowserClient } from "@/core/lib/supabase";
import {
  buttonPrimaryClassName,
  formFieldClassName,
  formLabelClassName
} from "@/core/ui/form-controls";
import { adminHomePath, isAdminRole } from "@/features/admin-auth/services/admin-access";

export const LoginForm = () => {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  return (
    <form
      className="mx-auto flex w-full max-w-md flex-col gap-4 rounded-xl border border-zinc-200 bg-white p-6 shadow-sm"
      onSubmit={async (event) => {
        event.preventDefault();
        setIsSubmitting(true);
        setErrorMessage(null);

        const supabase = createSupabaseBrowserClient();
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password
        });

        if (error || !data.session) {
          setIsSubmitting(false);
          setErrorMessage("Não foi possível entrar. Verifique e-mail e senha.");
          return;
        }

        const { data: profile, error: profileError } = await supabase
          .from("profiles")
          .select("role")
          .eq("id", data.user.id)
          .maybeSingle<{ role: string }>();

        if (profileError || !isAdminRole(profile?.role)) {
          await supabase.auth.signOut();
          setIsSubmitting(false);
          setErrorMessage(
            "Esta conta não tem permissão de administrador. Peça para um admin atualizar profiles.role."
          );
          return;
        }

        router.refresh();
        router.push(adminHomePath);
        setIsSubmitting(false);
      }}
    >
      <h1 className="text-2xl font-semibold text-zinc-900">Admin EcoWallet</h1>
      <p className="text-sm text-zinc-600">
        Entre com sua conta de operador para revisar descartes.
      </p>

      <label className="flex flex-col gap-1 text-sm">
        <span className={formLabelClassName}>E-mail</span>
        <input
          type="email"
          required
          className={formFieldClassName}
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
      </label>

      <label className="flex flex-col gap-1 text-sm">
        <span className={formLabelClassName}>Senha</span>
        <input
          type="password"
          required
          className={formFieldClassName}
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
      </label>

      {errorMessage ? (
        <p role="alert" className="text-sm text-red-700">
          {errorMessage}
        </p>
      ) : null}

      <button
        type="submit"
        disabled={isSubmitting}
        className={buttonPrimaryClassName}
      >
        {isSubmitting ? "Entrando..." : "Entrar"}
      </button>
    </form>
  );
};
