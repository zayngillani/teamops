"use client";

import { useState } from "react";
import { Send, Loader2, CheckCircle, Upload } from "lucide-react";
import { submitApplication } from "@/app/actions/recruitment";

interface JobApplicationFormProps {
  jobId: string;
}

export function JobApplicationForm({ jobId }: JobApplicationFormProps) {
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    resumeUrl: "",
    notes: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    const data = new FormData();
    data.append("jobId", jobId);
    data.append("name", formData.name);
    data.append("email", formData.email);
    data.append("resumeUrl", formData.resumeUrl);
    data.append("notes", formData.notes);

    try {
      await submitApplication(data);
      setSubmitted(true);
    } catch (error: any) {
      alert(error.message || "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  if (submitted) {
    return (
      <div className="py-12 text-center space-y-6 animate-in zoom-in duration-300">
        <div className="w-20 h-20 bg-green-500/10 rounded-full flex items-center justify-center mx-auto ring-1 ring-green-500/20">
          <CheckCircle className="w-10 h-10 text-green-500" />
        </div>
        <div className="space-y-2">
          <h4 className="text-xl font-bold">Application Received!</h4>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Thank you for your interest. Our team will review your application and get back to you shortly.
          </p>
        </div>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-1">
        <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Full Name</label>
        <input 
          required 
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3.5 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
          placeholder="Enter your name" 
        />
      </div>

      <div className="space-y-1">
        <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Email Address</label>
        <input 
          type="email" 
          required 
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3.5 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
          placeholder="email@example.com" 
        />
      </div>

      <div className="space-y-1">
        <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Resume / Portfolio Link</label>
        <div className="relative">
          <input 
            required 
            value={formData.resumeUrl}
            onChange={(e) => setFormData({ ...formData, resumeUrl: e.target.value })}
            className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3.5 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all pl-10" 
            placeholder="Link to PDF or Portfolio" 
          />
          <Upload className="w-4 h-4 text-muted-foreground absolute left-4 top-1/2 -translate-y-1/2" />
        </div>
      </div>

      <div className="space-y-1">
        <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Additional Notes</label>
        <textarea 
          rows={3}
          value={formData.notes}
          onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3.5 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all resize-none" 
          placeholder="Tell us something about yourself..." 
        />
      </div>

      <button 
        type="submit" 
        disabled={loading}
        className="w-full bg-primary hover:bg-primary-hover text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-[0.98] mt-4 disabled:opacity-50"
      >
        {loading ? (
          <Loader2 className="w-5 h-5 animate-spin" />
        ) : (
          <>
            <Send className="w-5 h-5" />
            Submit Application
          </>
        )}
      </button>
    </form>
  );
}
