import mongoose from "mongoose";

const serviceSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  price: {
    type: Number,
    default: 0
  },
  description: String,
  category: {
    type: String,
    enum: ["internal", "external"],
    default: "internal",
    index: true
  },
  type: {
    type: String,
    enum: ["tuition", "parking", "library", "canteen", "union_fee", "dormitory", "insurance", "other"],
  },
  scopeType: {
    type: String,
    enum: ["school", "cohort", "faculty", "cohort_faculty"],
    default: "school",
    index: true
  },
  applicableCohorts: {
    type: [String],
    default: []
  },
  applicableFaculties: {
    type: [String],
    default: []
  },
  requireActiveStudent: {
    type: Boolean,
    default: true
  },
  paymentWindow: {
    startAt: Date,
    endAt: Date,
    semester: String,
    academicYear: String,
    reminderDaysBeforeDue: {
      type: [Number],
      default: [5, 3, 1]
    }
  },
  parkingConfig: {
    perUsePrice: {
      type: Number,
      default: 0
    },
    monthlyPassEnabled: {
      type: Boolean,
      default: false
    },
    monthlyPassPrice: {
      type: Number,
      default: 0
    },
    monthlyPassOpenDayFrom: {
      type: Number,
      default: 1
    },
    monthlyPassOpenDayTo: {
      type: Number,
      default: 5
    }
  },
  icon: {
    type: String,
    default: "💳"
  },
  requireVerification: {
    type: Boolean,
    default: true
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, { timestamps: true });

export default mongoose.model("Service", serviceSchema);
