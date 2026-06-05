#!/usr/bin/nu
# nu shell script
# 
# Assemble the results files
#

def assemble-results [] {
  ls Generated/**/result.json | each { |result|
    let dataset = $result.name | split row '/' | get 1
    let samplenum = $result.name | split row '/' | get 2
    let rating = open $result.name | get best_agent.rating
    {
      dataset: $dataset,
      samplenum: $samplenum,
      rating: $rating
    }
  }
}
