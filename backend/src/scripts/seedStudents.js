// Script migrate mock data cũ vào Student collection
// Chạy: node src/scripts/seedStudents.js

import "dotenv/config";
import mongoose from "mongoose";
import Student from "../models/Student.js";

const deriveCohortFromStudentId = (studentId) => {
  const match = String(studentId || "").trim().match(/^(\d{2})/);
  return match ? `K${match[1]}` : "";
};

const oldMockStudents = [
  {
    studentId: "28211152394",
    fullName: "Mạc Văn Vinh",
    dateOfBirth: "2005-01-15",
    email: "macvanvinh@dtu.edu.vn",
    faculty: "Cong nghe thong tin",
  },
  {
    studentId: "SV2024002",
    fullName: "Tran Thi Bich",
    dateOfBirth: "2005-03-22",
    email: "bich.tran@university.edu.vn",
    faculty: "Ke toan",
  },
  {
    studentId: "SV2024003",
    fullName: "Le Hoang Minh",
    dateOfBirth: "2004-11-08",
    email: "minh.le@university.edu.vn",
    faculty: "Tai chinh ngan hang",
  },
  {
    studentId: "SV2024004",
    fullName: "Pham Gia Han",
    dateOfBirth: "2005-07-30",
    email: "han.pham@university.edu.vn",
    faculty: "Quan tri kinh doanh",
  },
  {
    studentId: "SV2024005",
    fullName: "Vo Duc Khang",
    dateOfBirth: "2004-12-19",
    email: "khang.vo@university.edu.vn",
    faculty: "Ky thuat phan mem",
  },
];

async function seedStudents() {
  try {
    await mongoose.connect(process.env.MONGODB_CONNECTIONSTRING);
    console.log("✅ Connected to MongoDB");

    let created = 0;
    let skipped = 0;

    for (const student of oldMockStudents) {
      const existing = await Student.findOne({ studentId: student.studentId });
      if (existing) {
      console.log(`⏭️  Skip: ${student.studentId} (đã tồn tại)`);
      skipped++;
    } else {
      await Student.create({
        ...student,
        cohort: deriveCohortFromStudentId(student.studentId),
        academicStatus: "studying",
      });
      console.log(`✅ Created: ${student.studentId} - ${student.fullName}`);
      created++;
      }
    }

    console.log(`\n🎉 Done! Created: ${created}, Skipped: ${skipped}`);
    process.exit(0);
  } catch (error) {
    console.error("❌ Seed error:", error);
    process.exit(1);
  }
}

seedStudents();
