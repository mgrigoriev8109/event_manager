require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.delete("^0-9")
  if phone_number.nil?
    phone_number = 'This phone number was not supplied'
  elsif phone_number.length < 10 || phone_number.length > 11
    puts "This phone number is invalid because it is less than 10 or greater than 11 numbers"
  elsif phone_number.length == 11 && phone_number[0] == 1
    puts phone_number.slice[1..-1]
  elsif phone_number.length == 11
    puts "This phone number is invalid because it is 11 numbers and does not start with 1"
  else 
    puts phone_number
  end
end

def registration_hours(hour)
  Time.strptime(hour, '%m/%d/%Y %H:%M').strftime("%H")
end

def registration_days(hour)
  Date.strptime(hour, '%m/%d/%Y').cwday
end

def count_occurances(array)
  array.reduce(Hash.new(0)) do |hash, count|
    hash[count] += 1
    hash
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours_registered = []
days_registered = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  #phone_number = clean_phone_number(row[:homephone])
  hours_registered.push(registration_hours(row[:regdate]))
  days_registered.push(registration_days(row[:regdate]))
  #form_letter = erb_template.result(binding)
  registration_days(row[:regdate])
  #save_thank_you_letter(id,form_letter)
end

p "An array showing which hours (military time) the most people registered on:"
p count_occurances(hours_registered).sort_by{|hour, count| -count}

p "An array showing which days (1 being monday, 7 sunday) the most people registered on:"
p count_occurances(days_registered).sort_by{|day, count| -count}