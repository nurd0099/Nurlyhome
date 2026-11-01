"use client";
import { Search } from "lucide-react";
import { useRouter } from "next/navigation";
import type { Locale } from "@/lib/i18n";
import { dictionaries } from "@/lib/i18n";
export function HomeSearch({ locale }: { locale: Locale }) {
 const t=dictionaries[locale]; const router=useRouter();
 function submit(formData: FormData){const params=new URLSearchParams(); for(const key of ["city","university","from","to"]) {const value=formData.get(key)?.toString().trim();if(value)params.set(key,value);} router.push(`/${locale}/search?${params.toString()}`);}
 return <form className="searchbar" action={submit}><div className="search-field"><label>{t.city}</label><select name="city" defaultValue=""><option value="">{t.cityPlaceholder}</option><option>Алматы</option><option>Астана</option><option>Шымкент</option><option>Караганда</option></select></div><div className="search-field"><label>{t.university}</label><input name="university" placeholder={t.universityPlaceholder}/></div><div className="search-field"><label>{t.moveIn}</label><input aria-label={t.moveIn} name="from" type="date"/></div><div className="search-field"><label>{t.moveOut}</label><input aria-label={t.moveOut} name="to" type="date"/></div><button className="primary-button" type="submit"><Search size={17}/>{t.search}</button></form>;
}
