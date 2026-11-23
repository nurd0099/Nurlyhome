import {notFound} from "next/navigation";
import {isLocale,dictionaries} from "@/lib/i18n";
import {exampleDorms} from "@/lib/dorms";
import {SiteHeader} from "@/components/site-header";
import {SiteFooter} from "@/components/site-footer";
import {Catalog} from "@/components/catalog";
import {getAvailableBeds,getPublicDorms} from "@/lib/data";
import {hasSupabaseConfig} from "@/lib/supabase";
export default async function SearchPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{
    city?: string;
    university?: string;
    from?: string;
    to?: string;
    gender?: string;
    maxPrice?: string;
    maxDistance?: string;
    minRating?: string;
    availableOnly?: string;
    capacity?: string;
    amenities?: string | string[];
    sort?: string;
    error?: string;
  }>;
}) {
  const { locale: raw } = await params;
  const rawParams = await searchParams;

  if (!isLocale(raw)) notFound();
  const locale = raw;
  const t = dictionaries[locale];

  const amenitiesList = Array.isArray(rawParams.amenities)
    ? rawParams.amenities
    : rawParams.amenities
    ? [rawParams.amenities]
    : [];

  const initial = {
    ...rawParams,
    availableOnly: rawParams.availableOnly === "1" || rawParams.availableOnly === "true",
    amenities: amenitiesList,
  };const listingResult=await getPublicDorms();const liveMode=hasSupabaseConfig();const useDemoListings=!liveMode||!listingResult?.dorms?.length;let dorms=useDemoListings?exampleDorms:listingResult.dorms;const dateRangeMismatch=liveMode&&!useDemoListings&&!listingResult?.error&&Boolean(initial.from&&initial.to)&&dorms.length>0&&!dorms.some(dorm=>dorm.semesterStart===initial.from&&dorm.semesterEnd===initial.to);if(liveMode&&!useDemoListings&&!listingResult?.error&&initial.from&&initial.to){const availability=await Promise.all(dorms.map(async dorm=>({dorm,beds:await getAvailableBeds(dorm.id,initial.from!,initial.to!)})));dorms=availability.filter(item=>item.beds.length>0).map(item=>({...item.dorm,beds:item.beds.length}))}const errorText=listingResult?.error?(locale==="ru"?"Не удалось загрузить реальные общежития. Показаны демонстрационные карточки.":locale==="kk"?"Нақты жатақханаларды жүктеу мүмкін болмады. Демонстрациялық карточкалар көрсетілді.":"Could not load live dorms. Demo listings are shown."):dateRangeMismatch?(locale==="ru"?"Заявки доступны только на полный семестр. Даты должны совпадать с датами семестра общежития.":locale==="kk"?"Өтінім тек толық семестрге қабылданады. Күндер жатақхананың семестр күндерімен сәйкес болуы керек.":"Requests are only available for a full semester. Dates must match the dorm's published semester."):initial.error==="login"?(locale==="ru"?"Войдите, чтобы отправить заявку.":locale==="kk"?"Өтінім жіберу үшін кіріңіз.":"Sign in to request a bed."):initial.error==="unavailable"?(locale==="ru"?"Место уже занято на эти даты. Обновите поиск.":locale==="kk"?"Бұл күндерде орын бос емес. Іздеуді жаңартыңыз.":"That bed is no longer available for those dates. Refresh your search."):initial.error? (locale==="ru"?"Не удалось отправить заявку. Проверьте даты и настройки.":locale==="kk"?"Өтінім жіберілмеді. Күндер мен баптауларды тексеріңіз.":"Could not submit the request. Check dates and configuration."):null;return <><SiteHeader locale={locale}/><main className="container"><div className="page-head"><div className="eyebrow">{t.searchLabel}</div><h1>{t.catalog}</h1><p className="muted">{initial.city?`${initial.city} · `:""}{initial.university||t.intro}</p>{initial.from&&initial.to&&<p className="muted">{t.moveIn}: {initial.from} · {t.moveOut}: {initial.to}</p>}{errorText&&<div className="disclaimer" role="alert">{errorText}</div>}<div className="disclaimer">{!useDemoListings?(locale==="ru"?"Показаны только одобренные объекты; свободные места проверяются по выбранному семестру.":locale==="kk"?"Тек мақұлданған нысандар көрсетіледі; бос орындар таңдалған семестр бойынша тексеріледі.":"Only approved properties are shown; available beds are checked against the selected semester."):locale==="ru"?"Демонстрационный режим: карточки не являются реальными объектами и не подтверждают наличие мест.":locale==="kk"?"Демонстрациялық режим: карточкалар нақты нысан емес және бос орындарды растамайды.":"Demo mode: listings are illustrative and do not confirm real availability."}</div></div><Catalog dorms={dorms} locale={locale} initial={initial}/></main><SiteFooter locale={locale}/></>}
