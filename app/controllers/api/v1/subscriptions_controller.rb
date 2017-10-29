class Api::V1::SubscriptionsController < Api::V1::BaseController
  # skip_before_action :authenticate_request

  def index
    puts params
    if params[:verify].present?
      verification = params[:verify]
      if verification == '68ffde8f767e49f4a6e6f99ff7efa93c5664cfe954e8d368701ebe08bd3cadb3'
        render body: nil, :status => 204
      else
        render body: nil, :status => 404
      end
    end
  end

  def create
    render body: nil, :status => 204
    @updates = params["_json"]
    @updates.each do |update|
      getuser(update)
      getHeartRate(update)
      getCalories(update)
    end
  end

  private

  def getuser(update)
    @updateUser = User.find(update[:ownerId])
  end

  def getHeartRate(update)
    @activities = @updateUser.sessions.where(heartrate: nil).where(template: false).order(completed_at: :desc)
    @activities.each do |activity|
      date = activity.started_at.strftime("%Y-%m-%d")
      start = activity.started_at.strftime("%H:%M:%S")
      finish = activity.completed_at.strftime("%H:%M:%S")
      hr = Curl::Easy.perform("https://api.fitbit.com/1/user/#{@updateUser[:user_id]}/activities/heart/date/#{date}/#{date}/1sec/time/#{start}/#{finish}.json") do |curl|
        curl.headers["Authorization"] = "Bearer #{@updateUser.token[:access_token]}"
      end
      if JSON.parse(hr.body)["errors"].present?
        puts hr.body
      else
        puts JSON.parse(hr.body)
        data = JSON.parse(hr.body)["activities-heart-intraday"]["dataset"]
        activity[:heartrate] = data
        if activity.save
          puts "saved successfully"
        else
          puts activity.errors.full_messages
        end
      end
    end
  end

  # https://api.fitbit.com/1/user/-/activities/calories/date/today/today/1min/time/12%3A00%3A00/12%3A39%3A00.json

  def getCalories(update)
    @activities = @updateUser.sessions.where(calories: nil).where(template: false).order(completed_at: :desc)
    @activities.each do |activity|
      date = activity.started_at.strftime("%Y-%m-%d")
      start = activity.started_at.strftime("%H:%M:%S")
      finish = activity.completed_at.strftime("%H:%M:%S")
      cal = Curl::Easy.perform("https://api.fitbit.com/1/user/#{@updateUser[:user_id]}/activities/calories/date/#{date}/#{date}/1min/time/#{start}/#{finish}.json") do |curl|
        curl.headers["Authorization"] = "Bearer #{@updateUser.token[:access_token]}"
      end
      if JSON.parse(cal.body)["errors"].present?
        puts cal.body
      else
        data = JSON.parse(cal.body)["activities-calories-intraday"]["dataset"]
        activity[:calories] = data
        if activity.save
          puts "saved successfully"
        else
          puts activity.errors.full_messages
        end
      end
    end
  end
end
