import { createSupabaseServerClient, hasSupabaseConfig } from "@/lib/supabase";
export type BookingRequest={bedId:string;checkIn:string;checkOut:string;paymentMethod:"on_site"|"kaspi_remote";paymentContact?:string};
export async function createBookingRequest(input:BookingRequest){
 if(!hasSupabaseConfig())return{ok:false as const,error:"not-configured"};
 const supabase=await createSupabaseServerClient();if(!supabase)return{ok:false as const,error:"not-configured"};
 const {data:{user},error:authError}=await supabase.auth.getUser();if(authError||!user)return{ok:false as const,error:"not-authenticated"};
 // The RPC enforces date, ownership, eligibility and overlap constraints within one database transaction.
 const {data,error}=await supabase.rpc("request_bed_booking",{p_bed_id:input.bedId,p_check_in:input.checkIn,p_check_out:input.checkOut,p_payment_method:input.paymentMethod,p_payment_contact:input.paymentContact||null});
 if(error)return{ok:false as const,error:error.code==="23P01"?"bed-unavailable":error.message};
 return{ok:true as const,bookingId:data as string};
}
