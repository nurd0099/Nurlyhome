import { createSupabaseServerClient, hasSupabaseConfig } from "@/lib/supabase";
import type { Dorm } from "@/lib/dorms";
type DormRow={id:string;name:string;city:string;university_name:string;distance_km:number|null;semester_price:number|null;rating:number|null;review_count:number|null;available_beds:number|null;gender:"women"|"men"|"mixed";amenities:string[]|null;cover_image:string|null;gallery_images:string[]|null;rules:string|null;address:string;description:string;room_count:number|null;semester_start:string;semester_end:string;payment_method:"on_site"|"kaspi_remote"|null;kaspi_phone:string|null};
function mapDorm(row:DormRow):Dorm{return{id:row.id,name:row.name,city:row.city,university:row.university_name,distance:Number(row.distance_km||0),price:Number(row.semester_price||0),rating:Number(row.rating||0),reviewCount:Number(row.review_count||0),beds:Number(row.available_beds||0),capacity:2,gender:row.gender,amenities:row.amenities||[],image:row.cover_image||row.gallery_images?.[0]||"",gallery:row.gallery_images||[],rules:row.rules||"",address:row.address,description:row.description,rooms:Number(row.room_count||0),semesterStart:row.semester_start,semesterEnd:row.semester_end,paymentMethod:row.payment_method||"on_site",kaspiPhone:row.kaspi_phone||undefined}}
export async function getPublicDorms(): Promise<{ dorms: Dorm[]; error: boolean } | null> {
 if(!hasSupabaseConfig())return null;const supabase=await createSupabaseServerClient();if(!supabase)return null;
  const {data,error}=await supabase.from("dormitories").select("id,name,city,university_name,distance_km,semester_price,rating,review_count,available_beds,gender,amenities,cover_image,gallery_images,rules,address,description,room_count,semester_start,semester_end,payment_method,kaspi_phone").eq("approval_status","approved").eq("is_active",true).order("created_at",{ascending:false});
 if(error){console.error("Could not load public dorms",error.message);return{dorms:[],error:true};}return{dorms:(data||[]).map((row)=>mapDorm(row as DormRow)),error:false};
}
export async function getDormById(id:string):Promise<Dorm|null>{
  if(!hasSupabaseConfig())return null;const supabase=await createSupabaseServerClient();if(!supabase)return null;
  const {data,error}=await supabase.from("dormitories").select("id,name,city,university_name,distance_km,semester_price,rating,review_count,available_beds,gender,amenities,cover_image,gallery_images,rules,address,description,room_count,semester_start,semester_end,payment_method,kaspi_phone").eq("id",id).eq("approval_status","approved").eq("is_active",true).maybeSingle();
 if(error||!data)return null;return mapDorm(data as DormRow);
}
export type PublicDormReview={rating:number;cleanliness:number|null;conditions:number|null;facilities:number|null;text:string;created_at:string};
export async function getDormReviews(dormId:string):Promise<PublicDormReview[]>{
 if(!hasSupabaseConfig())return[];const supabase=await createSupabaseServerClient();if(!supabase)return[];
 const {data,error}=await supabase.from("reviews").select("rating,cleanliness,conditions,facilities,text,created_at").eq("dormitory_id",dormId).eq("status","published").order("created_at",{ascending:false}).limit(20);
 if(error){console.error("Could not load dorm reviews",error.message);return[];}return(data||[]) as PublicDormReview[];
}
export type AvailableBed={bed_id:string;floor_number:number;room_number:string;bed_number:number;semester_price:number;room_amenities:string[]};
export async function getAvailableBeds(dormId:string,checkIn:string,checkOut:string):Promise<AvailableBed[]>{
 if(!hasSupabaseConfig())return[];const supabase=await createSupabaseServerClient();if(!supabase)return[];
 const {data,error}=await supabase.rpc("list_available_beds",{p_dorm_id:dormId,p_check_in:checkIn,p_check_out:checkOut});
 if(error){console.error("Could not load bed inventory",error.message);return[];}return(data||[]) as AvailableBed[];
}
