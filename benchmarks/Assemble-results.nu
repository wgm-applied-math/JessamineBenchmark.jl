#!/usr/bin/nu
# nu shell script
#
# Assemble the results files
#

def assemble-progress [] {
  ls Generated/**/progress.json | each { |result|
    let dataset = $result.name | split row '/' | get 1
    let samplenum = $result.name | split row '/' | get 2
    let result = open $result.name
    let rating = $result | get agent.rating | format number | get display
    let start_time = $result | get start_time
    let current_time = $result | get current_time
    {
      dataset: $dataset,
      samplenum: $samplenum,
      rating: $rating,
      current_time: $current_time,
      start_time: $start_time
    }
  }
}

def assemble-results [] {
  ls Generated/**/result.json | each { |result|
    let dataset = $result.name | split row '/' | get 1
    let samplenum = $result.name | split row '/' | get 2
    let rating = open $result.name | get discoveries.0.agent.rating | format number | get display
    {
      dataset: $dataset,
      samplenum: $samplenum,
      rating: $rating
    }
  }
}

def load-report [] {
  open Generated/full-report.csv
}

def best-runs [col="rating"] {
  (polars into-df
   | polars sort-by $col
   | polars group-by dataset
   | polars first
   | polars collect
   | polars sort-by dataset
   | polars into-nu
   | update $col { format number | get lowerexp } 
  )
}
