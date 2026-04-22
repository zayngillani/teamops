"use client";

import { signOut } from "next-auth/react";
import { Bell, Search, LogOut, Moon, Sun } from "lucide-react";
import { motion } from "framer-motion";

interface HeaderProps {
  user: {
    name?: string | null;
    email?: string | null;
  };
}

export function Header({ user }: HeaderProps) {
  return (
    <header className="h-20 border-b px-8 flex items-center justify-between sticky top-0 bg-background/80 backdrop-blur-md z-10">
      <div className="flex items-center space-x-4">
        {/* Search removed per request */}
      </div>

      <div className="flex items-center space-x-6">
        <button className="relative p-2 hover:bg-accent rounded-full transition-colors">
          <Bell className="w-5 h-5 text-muted-foreground" />
          <span className="absolute top-2 right-2 w-2 h-2 bg-primary rounded-full border-2 border-background" />
        </button>
        
        <div className="h-8 w-px bg-border mx-2" />
        
        <div className="flex items-center space-x-4">
          <div className="text-right hidden sm:block">
            <p className="text-sm font-bold">{user.name}</p>
            <p className="text-xs text-muted-foreground">Online</p>
          </div>
          <button 
            onClick={() => signOut({ callbackUrl: "/login" })}
            className="p-2 hover:bg-destructive/10 text-muted-foreground hover:text-destructive rounded-full transition-all active:scale-90"
            title="Sign Out"
          >
            <LogOut className="w-5 h-5" />
          </button>
        </div>
      </div>
    </header>
  );
}
