import { Briefcase, MapPin, Clock, ArrowRight, Globe } from "lucide-react";
import prisma from "@/lib/prisma";
import Link from "next/link";

export default async function PublicJobsPage() {
  const jobs = await prisma.jobPost.findMany({
    where: { status: "ACTIVE" },
    orderBy: { createdAt: "desc" }
  });

  return (
    <div className="min-h-screen bg-slate-950 text-white font-sans selection:bg-primary selection:text-white">
      {/* Navigation */}
      <nav className="border-b border-white/5 backdrop-blur-xl sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center font-bold">T</div>
            <span className="text-xl font-bold tracking-tighter">TeamOps <span className="text-primary text-xs uppercase ml-1">Careers</span></span>
          </div>
          <Link href="/login" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">
            Portal Login
          </Link>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-24 relative overflow-hidden">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-4xl h-96 bg-primary/10 blur-[120px] rounded-full -z-10" />
        <div className="max-w-4xl mx-auto px-6 text-center space-y-6">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-xs font-bold text-primary uppercase tracking-widest">
            <Globe className="w-3 h-3" />
            We are hiring remotely
          </div>
          <h1 className="text-6xl font-bold tracking-tighter leading-[1.1]">
            Help us build the future of <span className="gradient-text">Remote Operations.</span>
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto leading-relaxed">
            Join a high-performance team dedicated to building cutting-edge management tools for the modern workspace.
          </p>
        </div>
      </section>

      {/* Jobs Listing */}
      <section className="pb-32">
        <div className="max-w-4xl mx-auto px-6 space-y-6">
          <div className="flex items-center justify-between pb-4 border-b border-white/5">
            <h2 className="text-sm font-bold text-muted-foreground uppercase tracking-widest">Open Positions</h2>
            <span className="text-xs text-muted-foreground">{jobs.length} roles found</span>
          </div>

          <div className="grid gap-4">
            {jobs.length > 0 ? jobs.map((job: any) => (
              <Link key={job.id} href={`/jobs/${job.id}`}>
                <div className="glass p-8 rounded-[32px] border border-white/5 hover:border-primary/30 transition-all group flex items-center justify-between relative overflow-hidden">
                  <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity">
                    <ArrowRight className="w-5 h-5 text-primary" />
                  </div>
                  <div className="space-y-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-slate-900 rounded-2xl flex items-center justify-center">
                        <Briefcase className="w-5 h-5 text-primary" />
                      </div>
                      <div>
                        <h3 className="text-xl font-bold group-hover:text-primary transition-colors">{job.title}</h3>
                        <p className="text-sm text-muted-foreground">{job.department}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-6">
                      <div className="flex items-center gap-2 text-xs text-muted-foreground font-medium">
                        <MapPin className="w-3.5 h-3.5" />
                        Remote
                      </div>
                      <div className="flex items-center gap-2 text-xs text-muted-foreground font-medium">
                        <Clock className="w-3.5 h-3.5" />
                        Full-time
                      </div>
                    </div>
                  </div>
                </div>
              </Link>
            )) : (
              <div className="text-center py-24 glass rounded-[40px] border border-dashed border-white/10">
                <p className="text-muted-foreground italic">No open positions at the moment. Check back later!</p>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-white/5">
        <div className="max-w-4xl mx-auto px-6 text-center space-y-4">
          <p className="text-xs text-muted-foreground font-bold uppercase tracking-widest">© 2026 TeamOps Global</p>
          <p className="text-[10px] text-slate-600">Built with TeamOps Internal Portal</p>
        </div>
      </footer>
    </div>
  );
}
