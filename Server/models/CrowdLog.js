const mongoose = require('mongoose');

const crowdLogSchema = new mongoose.Schema({
  event:       { type: String, enum: ['ENTRY', 'EXIT'], required: true },
  count:       { type: Number, required: true },
  density:     { type: Number, required: true },
  status:      { type: String, enum: ['SAFE', 'MODERATE', 'OVERCROWDED'] },
  maxCapacity: { type: Number, default: 50 },
  timestamp:   { type: Date, default: Date.now }
});

module.exports = mongoose.model('CrowdLog', crowdLogSchema);