const express = require('express');
const router = express.Router();
const CrowdLog = require('../models/CrowdLog');

// Get latest logs
router.get('/', async (req, res) => {
  const logs = await CrowdLog.find().sort({ createdAt: -1 }).limit(20);
  res.json(logs);
});

module.exports = router;




// const express = require('express');
// const router  = express.Router();
// const CrowdLog = require('../models/CrowdLog');

// // GET latest count
// router.get('/latest', async (req, res) => {
//   try {
//     const latest = await CrowdLog.findOne().sort({ timestamp: -1 });
//     res.json(latest);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // GET history (last 100 logs)
// router.get('/history', async (req, res) => {
//   try {
//     const logs = await CrowdLog.find()
//       .sort({ timestamp: -1 })
//       .limit(100);
//     res.json(logs);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // GET stats summary
// router.get('/stats', async (req, res) => {
//   try {
//     const total   = await CrowdLog.countDocuments();
//     const alerts  = await CrowdLog.countDocuments({ status: 'OVERCROWDED' });
//     const latest  = await CrowdLog.findOne().sort({ timestamp: -1 });
//     res.json({ total, alerts, latest });
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// module.exports = router;