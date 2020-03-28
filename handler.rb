require 'json'
require 'cgi'
require 'date'
require 'base64'

API_GATEWAY_URL = 'conferenceHandler'

def lambda_handler(event:, context:)
    puts "#{event.inspect}"
    action = query_string(event,'action')
    puts "ACTION: #{action}"

    result = case action
    when 'in'
        action_in(event)
    when 'join'
        action_join(event)
    when 'callProgress'
        action_call_progress(event)
    when 'conferenceStatus'
        action_conference_status(event)
    end
    puts "#{result}"
    {
        statusCode: 200,
        headers: {
            'Content-Type' => 'text/html'
        },
        body: result
    }
rescue StandardError => e
    puts "ERROR"
    puts e.message
    puts e.backtrace
end

def action_call_progress(event)
end

def action_conference_status(event)
end

def action_in(event)
    <<-FOO
        <Response>
            <Gather action="#{API_GATEWAY_URL}?action=join" method="POST" numDigits="6" timeout="20">
                <Say>Hello, please enter your 6 digit conference number, followed by the pound sign.</Say>
                <Say language="fr-CA">Bonjour, veuillez entrer votre numéro de conférence à 6 chiffres, suivi du signe dièse.</Say>
            </Gather>
            <Say>Sorry, we did not receive your conference number. Please hang up, and try again.</Say>
        </Response>
    FOO
end

def action_join(event)
    params = post_body_params(event)
    room_number = params['Digits'].first
    room_number_say = room_number.split('').join(' ')
    conf_number = "zzz_#{room_number}"
    <<-FOO
        <Response>
            <Say>Thank you. Now connecting you to conference room #{room_number_say}</Say>
            <Dial>
                <Conference statusCallbackEvent="start end join leave mute hold speaker" statusCallback="#{API_GATEWAY_URL}?action=conferenceStatus" statusCallbackMethod="POST">#{conf_number}</Conference>
            </Dial>
        </Response>
    FOO
end

def query_string(event, key)
    event['queryStringParameters'][key]
end

def post_body_params(event)
    isBase64Encoded = event['isBase64Encoded']
    body = event['body']
    body = Base64.decode64(body) if isBase64Encoded
    params = CGI::parse(body)
end
