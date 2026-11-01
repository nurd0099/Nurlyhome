import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale,dictionaries } from "@/lib/i18n";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { AuthForm } from "@/components/auth-form";
export default async function LoginPage({params,searchParams}:{params:Promise<{locale:string}>;searchParams:Promise<{error?:string;checkEmail?:string}>}){const {locale:raw}=await params;const query=await searchParams;if(!isLocale(raw))notFound();const locale=raw;const t=dictionaries[locale];return <><SiteHeader locale={locale}/><main className="auth-wrap"><div className="auth-card"><div className="eyebrow">nurlyhome</div><h1>{t.login}</h1><p>{t.loginSubtitle}</p><AuthForm locale={locale} mode="login" error={query.error} checkEmail={Boolean(query.checkEmail)}/><p className="muted" style={{textAlign:"center",fontSize:13,marginTop:18}}>{t.authUnavailable}</p><p style={{textAlign:"center",fontSize:13}}><Link className="text-link" href={`/${locale}/auth/recover`}>{locale==="ru"?"Забыли пароль?":locale==="kk"?"Құпиясөзді ұмыттыңыз ба?":"Forgot password?"}</Link></p><p style={{textAlign:"center",fontSize:13}}><Link className="text-link" href={`/${locale}/auth/register`}>{t.signup}</Link></p></div></main><SiteFooter locale={locale}/></>}
