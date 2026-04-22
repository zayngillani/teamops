"use client";

import { useState } from "react";
import { updateUserToggles } from "@/app/actions/user";
import { Github, Linkedin, CheckCircle2, Coffee, Clock, ToggleLeft } from "lucide-react";

const ICON_MAP: Record<string, any> = {
  Github,
  Linkedin,
  CheckCircle2,
  Coffee,
  Clock,
  ToggleLeft,
};

interface FeatureToggleSwitchProps {
  userId: string;
  field: string;
  label: string;
  description: string;
  iconName?: string;
  initialValue?: boolean;
}

export function FeatureToggleSwitch({
  userId,
  field,
  label,
  description,
  iconName = "ToggleLeft",
  initialValue = false,
}: FeatureToggleSwitchProps) {
  const Icon = ICON_MAP[iconName] || ToggleLeft;
  const [enabled, setEnabled] = useState(initialValue);
  const [isPending, setIsPending] = useState(false);

  async function handleToggle() {
    setIsPending(true);
    const newValue = !enabled;
    setEnabled(newValue);
    try {
      await updateUserToggles(userId, { [field]: newValue });
    } catch (error) {
      console.error("Failed to update toggle", error);
      setEnabled(!newValue); // revert
    } finally {
      setIsPending(false);
    }
  }

  return (
    <div className="flex items-center justify-between p-6 bg-slate-900/50 border border-white/5 rounded-2xl transition-all hover:border-white/10">
      <div className="flex items-start gap-4">
        <div className={`p-3 rounded-xl ${enabled ? "bg-primary/20 text-primary" : "bg-white/5 text-muted-foreground"}`}>
          <Icon className="w-5 h-5" />
        </div>
        <div>
          <p className="font-bold text-white text-sm">{label}</p>
          <p className="text-xs text-muted-foreground mt-1 max-w-sm">{description}</p>
        </div>
      </div>
      <button
        onClick={handleToggle}
        disabled={isPending}
        className={`w-12 h-6 rounded-full relative transition-colors ${
          enabled ? "bg-primary" : "bg-slate-700"
        } ${isPending ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`}
      >
        <div
          className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow-sm transition-transform ${
            enabled ? "right-1" : "left-1"
          }`}
        />
      </button>
    </div>
  );
}
