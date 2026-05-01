// Cập nhật cohort cho sinh viên cũ dựa trên 2 số đầu MSSV
// Chạy: node src/scripts/backfillStudentCohorts.js

import "dotenv/config";
import mongoose from "mongoose";
import Student from "../models/Student.js";

const deriveCohortFromStudentId = (studentId) => {
  const match = String(studentId || "").trim().match(/^(\d{2})/);
  return match ? `K${match[1]}` : "";
};

async function backfillStudentCohorts() {
  try {
    await mongoose.connect(process.env.MONGODB_CONNECTIONSTRING);
    console.log("Connected to MongoDB");

    const students = await Student.find({
      $or: [{ cohort: { $exists: false } }, { cohort: "" }, { academicStatus: { $exists: false } }],
    });

    let updated = 0;
    let skipped = 0;

    for (const student of students) {
      const cohort = student.cohort || deriveCohortFromStudentId(student.studentId);
      if (!cohort) {
        skipped++;
        continue;
      }

      student.cohort = cohort;
      student.academicStatus = student.academicStatus || "studying";
      await student.save();
      updated++;
    }

    console.log(`Done. Updated: ${updated}, skipped: ${skipped}`);
    process.exit(0);
  } catch (error) {
    console.error("Backfill error:", error);
    process.exit(1);
  }
}

backfillStudentCohorts();
