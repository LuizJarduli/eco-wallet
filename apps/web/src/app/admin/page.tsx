import { redirect } from "next/navigation";

import { adminHomePath } from "@/features/admin-auth/services/admin-access";

export default function AdminIndexPage() {
  redirect(adminHomePath);
}
