input {
  tcp {
    port  => 5000
    codec => json_lines
  }
}

filter {
  # One index per application ("app" field added by logback), then per day.
  if [app] {
    mutate { add_field => { "[@metadata][index]" => "logs-%{app}" } }
  } else {
    mutate { add_field => { "[@metadata][index]" => "logs-unknown" } }
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "%{[@metadata][index]}-%{+YYYY.MM.dd}"
  }
}
