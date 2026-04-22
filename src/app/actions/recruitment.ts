"use server";

import prisma from "@/lib/prisma";
import { revalidatePath } from "next/cache";

export async function submitApplication(formData: FormData) {
  const jobId = formData.get("jobId") as string;
  const name = formData.get("name") as string;
  const email = formData.get("email") as string;
  const resumeUrl = formData.get("resumeUrl") as string; // Placeholder for file upload
  const notes = formData.get("notes") as string;

  if (!jobId || !name || !email) {
    throw new Error("Missing required fields.");
  }

  const application = await prisma.application.create({
    data: {
      jobId,
      name,
      email,
      resumeUrl,
      status: "NEW",
    }
  });

  revalidatePath("/dashboard/recruitment");
  return application;
}
