import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "nurlyhome — Student housing, made simpler",
  description: "Find student housing near your university in Kazakhstan.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ru" suppressHydrationWarning><body>{children}</body></html>;
}
