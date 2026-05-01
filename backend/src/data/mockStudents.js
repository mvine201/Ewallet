import Student from "../models/Student.js";

// Dữ liệu sinh viên giờ hoàn toàn lấy từ database (Student model)
// Không còn dùng mock data hardcoded nữa
const deriveCohortFromStudentId = (studentId) => {
  const match = String(studentId || "").trim().match(/^(\d{2})/);
  return match ? `K${match[1]}` : "";
};

export const findStudentById = async (studentId) => {
  if (!studentId) return null;

  try {
    const dbStudent = await Student.findOne({
      studentId: { $regex: new RegExp(`^${studentId.trim()}$`, "i") },
      isActive: true
    });

    if (dbStudent) {
      return {
        studentId: dbStudent.studentId,
        fullName: dbStudent.fullName,
        dateOfBirth: dbStudent.dateOfBirth,
        email: dbStudent.email,
        cohort: dbStudent.cohort || deriveCohortFromStudentId(dbStudent.studentId),
        faculty: dbStudent.faculty,
        academicStatus: dbStudent.academicStatus,
      };
    }
  } catch (error) {
    console.error("findStudentById DB error:", error);
  }

  return null;
};
