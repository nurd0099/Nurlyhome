"use server";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createBookingRequest } from "@/lib/bookings";
const schema=z.object({bedId:z.string().uuid(),checkIn:z.string().date(),checkOut:z.string().date()});
export async function submitBooking(formData:FormData){const locale=formData.get("locale")==="kk"?"kk":formData.get("locale")==="en"?"en":"ru";const parsed=schema.safeParse({bedId:formData.get("bedId"),checkIn:formData.get("checkIn"),checkOut:formData.get("checkOut")});if(!parsed.success)redirect(`/${locale}/search?error=invalid-dates`);const result=await createBookingRequest({bedId:parsed.data.bedId,checkIn:parsed.data.checkIn,checkOut:parsed.data.checkOut});if(!result.ok){const error=result.error==="not-authenticated"?"login":result.error==="not-configured"?"setup":result.error==="bed-unavailable"?"unavailable":"failed";redirect(`/${locale}/search?error=${error}`)}redirect(`/${locale}/account?request=sent`)}
