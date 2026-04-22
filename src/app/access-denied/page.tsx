import { ShieldAlert, Globe, MapPin } from "lucide-react";
import Link from "next/link";

export default function AccessDeniedPage() {
  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
      <div className="glass max-w-md w-full p-12 rounded-[40px] text-center space-y-8 border-destructive/20 relative overflow-hidden">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-destructive to-transparent opacity-50" />
        
        <div className="w-24 h-24 bg-destructive/10 rounded-3xl flex items-center justify-center mx-auto ring-1 ring-destructive/20">
          <ShieldAlert className="w-12 h-12 text-destructive animate-pulse" />
        </div>

        <div className="space-y-2">
          <h1 className="text-3xl font-bold tracking-tighter text-white">Access Denied</h1>
          <p className="text-muted-foreground text-sm leading-relaxed">
            Your current IP address is not authorized to access the TeamOps Portal from this location.
          </p>
        </div>

        <div className="bg-slate-900/50 rounded-2xl p-6 border border-border space-y-4">
          <div className="flex items-center justify-between text-xs font-bold text-muted-foreground uppercase">
            <span>Security Protocol</span>
            <span className="text-destructive">Active</span>
          </div>
          <div className="flex items-center gap-3 text-left">
            <Globe className="w-5 h-5 text-primary" />
            <div>
              <p className="text-[10px] text-muted-foreground uppercase font-bold">Network Location</p>
              <p className="text-sm font-mono text-white">Unauthorized External IP</p>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <p className="text-xs text-muted-foreground italic">
            If you are working remotely, please contact your administrator to enable "Outside Access" for your account.
          </p>
          <Link 
            href="/login"
            className="block w-full bg-slate-800 hover:bg-slate-700 text-white py-4 rounded-2xl font-bold transition-all active:scale-95"
          >
            Return to Login
          </Link>
        </div>
      </div>
    </div>
  );
}
