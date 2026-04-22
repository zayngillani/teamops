"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "framer-motion";
import {
  LayoutDashboard,
  Clock,
  FileText,
  Calendar,
  Linkedin,
  Key,
  Settings,
  Users,
  CheckCircle2,
  Briefcase,
  ToggleLeft,
  ThumbsUp,
  Github
} from "lucide-react";
import { cn } from "@/lib/utils";

const iconMap: Record<string, any> = {
  LayoutDashboard,
  Clock,
  FileText,
  Calendar,
  Linkedin,
  Key,
  Settings,
  Users,
  CheckCircle2,
  Briefcase,
  ToggleLeft,
  ThumbsUp,
  Github
};

interface SidebarNavProps {
  items: { title: string; href: string; icon: string; always?: boolean }[];
  user: {
    name?: string | null;
    email?: string | null;
    role: string;
  };
}

export function SidebarNav({ items, user }: SidebarNavProps) {
  const pathname = usePathname();

  return (
    <aside className="w-72 glass border-r h-screen sticky top-0 flex flex-col">
      <div className="p-8">
        <h1 className="text-2xl font-bold font-display gradient-text">TeamOps</h1>
      </div>

      <nav className="flex-1 px-4 space-y-2 overflow-y-auto pb-4 custom-scrollbar">
        {items.map((item) => {
          const isActive = pathname === item.href;
          const IconComponent = iconMap[item.icon];
          
          return (
            <Link key={item.href} href={item.href}>
              <div
                className={cn(
                  "group flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-200",
                  isActive
                    ? "bg-primary text-white shadow-lg shadow-primary/20"
                    : "hover:bg-accent text-muted-foreground hover:text-foreground"
                )}
              >
                <div className="flex items-center space-x-3">
                  {IconComponent && <IconComponent className={cn("w-5 h-5", isActive ? "text-white" : "group-hover:text-primary")} />}
                  <span className="font-medium text-sm">{item.title}</span>
                </div>
                {isActive && (
                  <motion.div layoutId="active" className="w-1.5 h-1.5 rounded-full bg-white" />
                )}
              </div>
            </Link>
          );
        })}
      </nav>

      <div className="p-4 mt-auto border-t border-white/5">
        <div className="glass rounded-2xl p-4 flex items-center space-x-3">
          <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold">
            {user.name?.[0] || user.email?.[0] || "U"}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold truncate">{user.name}</p>
            <p className="text-xs text-muted-foreground truncate uppercase tracking-wider">{user.role.replace("_", " ")}</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
