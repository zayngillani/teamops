import { ArrowLeft, MapPin, Clock, Check, Send, ShieldCheck, Briefcase } from "lucide-react";
import prisma from "@/lib/prisma";
import Link from "next/link";
import { notFound } from "next/navigation";
import { JobApplicationForm } from "@/components/recruitment/job-application-form";

export default async function JobDetailPage({ params }: { params: { id: string } }) {
  const job = await prisma.jobPost.findUnique({
    where: { id: params.id }
  });

  if (!job) notFound();

  return (
    <div className="min-h-screen bg-slate-950 text-white font-sans">
      {/* Navigation */}
      <nav className="border-b border-white/5 backdrop-blur-xl sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 h-20 flex items-center justify-between">
          <Link href="/jobs" className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-white transition-colors">
            <ArrowLeft className="w-4 h-4" />
            Back to All Jobs
          </Link>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center font-bold">T</div>
          </div>
        </div>
      </nav>

      <div className="max-w-6xl mx-auto px-6 py-16 grid grid-cols-1 lg:grid-cols-3 gap-16">
        {/* Content */}
        <div className="lg:col-span-2 space-y-12">
          <div className="space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-xs font-bold text-primary uppercase tracking-widest">
              {job.department}
            </div>
            <h1 className="text-5xl font-bold tracking-tighter leading-tight">{job.title}</h1>
            <div className="flex items-center gap-8 text-sm text-muted-foreground font-medium">
              <div className="flex items-center gap-2">
                <MapPin className="w-4 h-4 text-primary" />
                Remote
              </div>
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-primary" />
                Full-time
              </div>
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-primary" />
                Secure Application
              </div>
            </div>
          </div>

          <div className="prose prose-invert prose-slate max-w-none">
            <h3 className="text-xl font-bold mb-4">About the Role</h3>
            <p className="text-muted-foreground leading-relaxed whitespace-pre-wrap">
              {job.description}
            </p>
          </div>

          <div className="space-y-6 pt-8 border-t border-white/5">
            <h3 className="text-xl font-bold">What we offer</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {[
                "100% Remote-first culture",
                "Cutting edge tech stack",
                "Professional growth & learning stipend",
                "Health & Wellness benefits",
                "Annual team retreats",
                "Performance-based bonuses"
              ].map((benefit, i) => (
                <div key={i} className="flex items-center gap-3 text-sm text-muted-foreground">
                  <div className="w-5 h-5 rounded-full bg-green-500/10 flex items-center justify-center">
                    <Check className="w-3 h-3 text-green-500" />
                  </div>
                  {benefit}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Sidebar Application Form */}
        <div className="relative">
          <div className="sticky top-32 glass p-8 rounded-[40px] border border-white/10 space-y-8">
            <div className="space-y-2">
              <h3 className="text-2xl font-bold tracking-tighter">Apply for this role</h3>
              <p className="text-sm text-muted-foreground">We respond to all applications within 48 hours.</p>
            </div>
            
            <JobApplicationForm jobId={job.id} />

            <div className="pt-6 border-t border-white/5">
              <p className="text-[10px] text-center text-muted-foreground uppercase font-bold tracking-widest leading-relaxed">
                By applying, you agree to our <br /> Data Privacy and Recruitment Policy.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
