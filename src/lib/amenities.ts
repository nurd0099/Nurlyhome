export const amenityOptions = ["Wi-Fi", "Laundry", "Kitchen", "Security", "Study room", "CCTV", "Gym", "Parking"] as const;

export type Amenity = (typeof amenityOptions)[number];
