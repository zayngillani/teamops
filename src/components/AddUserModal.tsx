"use client";

import { useState } from "react";
import { UserPlus, X, ChevronRight, ChevronLeft, Check, Shield, Globe, Users as UsersIcon } from "lucide-react";
import { motion } from "framer-motion";
import { createUser } from "@/app/actions/user";
import { cn } from "@/lib/utils";

export default function AddUserModal() {
  const [isOpen, setIsOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState(1);
  const totalSteps = 4;

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    role: "developer",
    status: "active",
    userType: "DEVELOPER",
    githubUser: "",
    slackId: "",
    joinDate: new Date().toISOString().split("T")[0],
    canOutsideAccess: "false",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (step < totalSteps) {
      setStep(step + 1);
      return;
    }

    setLoading(true);
    const data = new FormData();
    Object.entries(formData).forEach(([key, value]) => data.append(key, value));
    
    try {
      await createUser(data);
      setIsOpen(false);
      setStep(1);
    } catch (error) {
      alert("Failed to create user");
    } finally {
      setLoading(false);
    }
  };

  const renderStep = () => {
    switch (step) {
      case 1:
        return (
          <div className="space-y-4 animate-in slide-in-from-right duration-300">
            <div className="space-y-1">
              <label className="text-xs font-bold text-muted-foreground uppercase ml-1">Full Name</label>
              <input 
                required 
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                placeholder="Ali Gillani" 
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-muted-foreground uppercase ml-1">Email Address</label>
              <input 
                type="email" 
                required 
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                placeholder="ali@example.com" 
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-muted-foreground uppercase ml-1">Password</label>
              <input 
                type="password" 
                required 
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                placeholder="••••••••" 
              />
            </div>
          </div>
        );
      case 2:
        return (
          <div className="space-y-4 animate-in slide-in-from-right duration-300">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-xs font-bold text-muted-foreground uppercase ml-1">Role</label>
                <select 
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                  className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all appearance-none"
                >
                  <option value="developer">Developer</option>
                  <option value="content_creator">Content Creator</option>
                  <option value="outreach_specialist">Outreach Specialist</option>
                  <option value="devops">DevOps</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <div className="space-y-1">
                <label className="text-xs font-bold text-muted-foreground uppercase ml-1">Status</label>
                <select 
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                  className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all appearance-none"
                >
                  <option value="active">Active</option>
                  <option value="pending">Pending</option>
                  <option value="suspended">Suspended</option>
                </select>
              </div>
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-muted-foreground uppercase ml-1">User Type</label>
              <select 
                value={formData.userType}
                onChange={(e) => setFormData({ ...formData, userType: e.target.value })}
                className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all appearance-none"
              >
                <option value="DEVELOPER">Developer</option>
                <option value="CONTENT_CREATOR">Content Creator</option>
                <option value="OUTREACH">Outreach</option>
                <option value="DEVOPS">DevOps</option>
                <option value="QA">QA</option>
                <option value="HR">HR</option>
                <option value="INTERN">Intern</option>
              </select>
            </div>
          </div>
        );
      case 3:
        return (
          <div className="space-y-4 animate-in slide-in-from-right duration-300">
            <div className="space-y-1">
              <label className="text-xs font-bold text-muted-foreground uppercase ml-1">GitHub Username</label>
              <input 
                value={formData.githubUser}
                onChange={(e) => setFormData({ ...formData, githubUser: e.target.value })}
                className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                placeholder="github_handle" 
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-muted-foreground uppercase ml-1">Slack Member ID</label>
              <input 
                value={formData.slackId}
                onChange={(e) => setFormData({ ...formData, slackId: e.target.value })}
                className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                placeholder="U12345678" 
              />
            </div>
          </div>
        );
      case 4:
        return (
          <div className="space-y-4 animate-in slide-in-from-right duration-300">
            <div className="space-y-1">
              <label className="text-xs font-bold text-muted-foreground uppercase ml-1">Joining Date</label>
              <input 
                type="date"
                value={formData.joinDate}
                onChange={(e) => setFormData({ ...formData, joinDate: e.target.value })}
                className="w-full bg-slate-900/50 text-white border border-white/10 rounded-xl px-4 py-3 outline-none focus:ring-2 focus:ring-primary/50 transition-all [color-scheme:dark]" 
              />
            </div>
            <div className="pt-4">
              <div className="flex items-center justify-between p-4 bg-slate-900/50 border border-white/10 rounded-2xl">
                <div className="flex items-center gap-3">
                  <Globe className="w-5 h-5 text-primary" />
                  <div>
                    <p className="text-sm font-bold text-white">Outside IP Access</p>
                    <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-wider">Security Bypass</p>
                  </div>
                </div>
                <input 
                  type="checkbox"
                  checked={formData.canOutsideAccess === "true"}
                  onChange={(e) => setFormData({ ...formData, canOutsideAccess: e.target.checked ? "true" : "false" })}
                  className="w-5 h-5 accent-primary"
                />
              </div>
            </div>
          </div>
        );
    }
  };

  return (
    <>
      <button 
        onClick={() => setIsOpen(true)}
        className="bg-primary hover:bg-primary-hover text-white px-6 py-3 rounded-2xl font-bold flex items-center gap-2 transition-all active:scale-95"
      >
        <UserPlus className="w-5 h-5" />
        Add User
      </button>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-950/60 backdrop-blur-sm" onClick={() => setIsOpen(false)} />
          <div className="glass relative w-full max-w-md rounded-[40px] p-8 shadow-2xl border border-white/10 animate-in fade-in zoom-in duration-200 max-h-[90vh] overflow-y-auto custom-scrollbar">
            <div className="absolute top-0 left-0 w-full h-1 bg-slate-800">
              <motion.div 
                className="h-full bg-primary"
                initial={{ width: 0 }}
                animate={{ width: `${(step / totalSteps) * 100}%` }}
              />
            </div>

            <div className="flex items-center justify-between mb-8 pt-4">
              <div>
                <h3 className="text-2xl font-bold text-white">Onboarding</h3>
                <p className="text-xs font-bold text-primary uppercase tracking-widest">Step {step} of {totalSteps}</p>
              </div>
              <button onClick={() => setIsOpen(false)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-8">
              <div className="min-h-[240px]">
                {renderStep()}
              </div>

              <div className="flex gap-4">
                {step > 1 && (
                  <button 
                    type="button"
                    onClick={() => setStep(step - 1)}
                    className="flex-1 bg-slate-800 hover:bg-slate-700 text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all"
                  >
                    <ChevronLeft className="w-5 h-5" />
                    Back
                  </button>
                )}
                <button 
                  type="submit" 
                  disabled={loading}
                  className={cn(
                    "flex-1 py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-[0.98] disabled:opacity-50",
                    step === totalSteps ? "bg-primary text-white" : "bg-white text-slate-950 hover:bg-slate-200"
                  )}
                >
                  {loading ? (
                    <Loader2 className="w-5 h-5 animate-spin" />
                  ) : step === totalSteps ? (
                    <>
                      <Check className="w-5 h-5" />
                      Complete
                    </>
                  ) : (
                    <>
                      Next
                      <ChevronRight className="w-5 h-5" />
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

function Loader2({ className }: { className?: string }) {
  return (
    <svg className={cn("animate-spin", className)} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
  );
}
