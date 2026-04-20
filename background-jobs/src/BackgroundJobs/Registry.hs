module BackgroundJobs.Registry where

import BackgroundJobs.FileJob

type AppRegistry =
  '[ '("file_queue", FileJob)
   ]
