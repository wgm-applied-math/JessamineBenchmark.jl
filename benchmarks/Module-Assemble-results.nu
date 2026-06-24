#!/usr/bin/nu
# nu shell script
#
# Assemble the results files
#

def assemble-progress [] {
  ls Generated/**/progress.json | each { |result|
    let path_parts = $result.name | split row '/'
    let run_set = $path_parts.1
    let data_set = $path_parts.2
    let sample_num = $path_parts.3
    let result = open $result.name
    let rating = $result | get agent.rating? | default "-1"
    let start_time = $result | get start_time? | default null
    let current_time = $result | get current_time? | default null
    {
      run_set: $run_set,
      data_set: $data_set,
      sample_num: $sample_num,
      rating: $rating,
      current_time: $current_time,
      start_time: $start_time
    }
  }
}

def assemble-results [] {
  ls Generated/**/result.json | each { |result|
    let path_parts = $result.name | split row '/'
    let run_set = $path_parts.1
    let data_set = $path_parts.2
    let sample_num = $path_parts.3
    let rating = open $result.name | get discoveries.0?.agent.rating | default nan
    {
      run_set: $run_set,
      data_set: $data_set,
      sample_num: $sample_num,
      rating: $rating
    }
  }
}

def load-report [] {
  open Generated/full-report.csv
}

def nice-nums [] {
  update rating { format number | get lowerexp } 
}

def best-runs [col="rating"] {
  (polars into-df
   | polars sort-by $col
   | polars group-by run_set data_set
   | polars first
   | polars collect
   | polars sort-by run_set data_set
   | polars into-nu
   | update $col { format number | get lowerexp } 
  )
}

def data-set-counts [] {
  (polars into-df
   | polars group-by run_set data_set
   | polars agg (polars col data_set | polars count | polars as "count")
   | polars collect
  | polars sort-by data_set
  | polars into-nu)
}
