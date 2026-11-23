"use server";
import { redirect } from "next/navigation";
import { createSupabaseServerClient, hasSupabaseConfig } from "@/lib/supabase";

export async function setDormActive(formData: FormData) {
  const locale = formData.get("locale") === "kk" ? "kk" : formData.get("locale") === "en" ? "en" : "ru";
  const dormId = String(formData.get("dormId") || "").trim();
  const active = formData.get("active") === "true";
  if (!dormId) redirect(`/${locale}/admin?error=invalid`);
  if (!hasSupabaseConfig()) redirect(`/${locale}/admin?error=setup`);
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect(`/${locale}/admin?error=setup`);
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/auth/login?next=admin`);
  const { error } = await supabase.rpc("admin_set_dorm_active", { p_dorm_id: dormId, p_active: active });
  if (error) redirect(`/${locale}/admin?error=admin_action`);
  redirect(`/${locale}/admin?dormUpdated=1`);
}
