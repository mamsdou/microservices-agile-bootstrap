input {
  tcp {
    port  => 5000
    codec => json_lines
  }
}

filter {
  # Un index par application (champ "app" ajoute par logback), puis par jour.
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
