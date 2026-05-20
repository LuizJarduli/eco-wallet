"use client";

import { useState } from "react";

import { createSupabaseBrowserClient } from "@/core/lib/supabase";
import { adminHomePath } from "@/features/admin-auth/services/admin-access";

export const LoginForm = () => {
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
        const { error } = await supabase.auth.signInWithPassword({
          email,
          password
        });

        setIsSubmitting(false);

        if (error) {
          setErrorMessage("Não foi possível entrar. Verifique e-mail e senha.");
          return;
        }

        window.location.assign(adminHomePath);
      }}
    >
      <h1 className="text-2xl font-semibold text-zinc-900">Admin EcoWallet</h1>
      <p className="text-sm text-zinc-600">
        Entre com sua conta de operador para revisar descartes.
      </p>

      <label className="flex flex-col gap-1 text-sm">
        <span className="font-medium text-zinc-700">E-mail</span>
        <input
          type="email"
          required
          className="rounded-md border border-zinc-300 px-3 py-2"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
      </label>

      <label className="flex flex-col gap-1 text-sm">
        <span className="font-medium text-zinc-700">Senha</span>
        <input
          type="password"
          required
          className="rounded-md border border-zinc-300 px-3 py-2"
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
        className="rounded-md bg-zinc-900 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
      >
        {isSubmitting ? "Entrando..." : "Entrar"}
      </button>
    </form>
  );
};
