require 'teamcity'

def update_builds(build_id)
  builds = []
  buildDateTime = ''
  lastCommitUser=''
  jobName=''
  keyVal=[]
  build = TeamCity.build(id: TeamCity.builds(count: 1, buildType: build_id).first.id)
  jsonBuildData = build.to_json
  buildData = JSON.parse(jsonBuildData)

  finishDateTime = DateTime.parse(buildData['finishDate'])

  buildDateTime = "#{finishDateTime.day}-#{finishDateTime.month}-#{finishDateTime.year} #{finishDateTime.hour}:#{finishDateTime.min}"

  keyVal ={
      "LAST BUILD" => buildData['number'].to_s,
      "LAST COMMIT BY"=> buildData['lastChanges']['change'][0]['username'],
      "STATUS"=> buildData['status'].to_s,
      "STATE"=> buildData['state'].to_s,
	  "BUILD DATE"=> buildDateTime
  }

  teamcityJobList = Array.new

  keyVal.each do |line|
    teamcityJobList.push({
                             label: line[0],
                             value: line[1],
                             state: build.status
                         }
    )

  end
  teamcityJobList
end

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/teamcity.yml'
config = YAML::load(File.open(config_file))

TeamCity.configure do |c|
  c.endpoint = config["api_url"]
  c.http_user = config["http_user"]
  c.http_password = config["http_password"]
end

SCHEDULER.every("15m", first_in: '1s') do
  unless config["repositories"].nil?
    config["repositories"].each do |data_id, build_id|
      #puts "kamal ==========================> #{data_id}"
      send_event(data_id, { items: update_builds(build_id)})
    end
  else
    puts "No TeamCity repositories found :("
  end
end
