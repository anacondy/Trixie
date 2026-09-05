import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "Sandbox Fingerprint — Field Report",
  description:
    "A live characterization of the environment this app runs in: template ID, VM, cgroup limits, database placement, egress, preview surface and persistence.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-zinc-950 font-mono text-zinc-200 antialiased">
        {children}
      </body>
    </html>
  );
}
