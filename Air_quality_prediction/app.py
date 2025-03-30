from flask import Flask, request, jsonify
import joblib
import numpy as np
import threading
import time
import serial
from datetime import datetime, timedelta
import json
import os

app = Flask(__name__)

# Load the trained models and scalers
print("========== INITIALIZATION ==========")
print("Loading models and scalers...")
try:
    individual_models = {
        "NH3_AQI": joblib.load("NH3_AQI_model.pkl"),
        "CO_AQI": joblib.load("CO_AQI_model.pkl"),
        "O3_AQI": joblib.load("O3_AQI_model.pkl"),
        "CH4_AQI": joblib.load("CH4_AQI_model.pkl")
    }

    individual_scalers = {
        "NH3_AQI": joblib.load("NH3_AQI_scaler.pkl"),
        "CO_AQI": joblib.load("CO_AQI_scaler.pkl"),
        "O3_AQI": joblib.load("O3_AQI_scaler.pkl"),
        "CH4_AQI": joblib.load("CH4_AQI_scaler.pkl")
    }

    overall_scaler = joblib.load("overall_aqi_scaler.pkl")
    overall_model = joblib.load("best_overall_aqi_model.pkl")
    print("Models and scalers loaded successfully.")
except Exception as e:
    print(f"ERROR loading models: {e}")
    raise

# Function to map AQI to category
def map_aqi_category(aqi):
    if aqi <= 50:
        return "Good"
    elif aqi <= 100:
        return "Moderate"
    elif aqi <= 150:
        return "Unhealthy for Sensitive Groups"
    elif aqi <= 200:
        return "Unhealthy"
    elif aqi <= 300:
        return "Very Unhealthy"
    else:
        return "Hazardous"

# Function to predict all AQIs
def predict_all_aqi(nh3_ppm, co_ppm, o3_ppm, ch4_ppm):
    print(f"\n========== PREDICTION START ==========")
    print(f"Predicting AQI with inputs: NH3={nh3_ppm}, CO={co_ppm}, O3={o3_ppm}, CH4={ch4_ppm}")
    
    try:
        # Prepare input data for individual AQIs
        input_data = {
            "NH3_AQI": np.array([[nh3_ppm]]),
            "CO_AQI": np.array([[co_ppm]]),
            "O3_AQI": np.array([[o3_ppm]]),
            "CH4_AQI": np.array([[ch4_ppm]])
        }

        # Prepare input data for Overall AQI
        overall_input = np.array([[nh3_ppm, co_ppm, ch4_ppm]])
        print(f"Prepared input arrays for prediction")

        # Scale inputs for individual AQIs
        scaled_inputs = {}
        for target, data in input_data.items():
            scaled_inputs[target] = individual_scalers[target].transform(data)
        
        # Scale input for Overall AQI
        overall_input_scaled = overall_scaler.transform(overall_input)
        print(f"Scaled all inputs successfully")

        # Make predictions for individual AQIs
        predictions = {}
        for target, scaled_data in scaled_inputs.items():
            predictions[target] = float(individual_models[target].predict(scaled_data)[0])
            print(f"Predicted {target}: {predictions[target]:.2f}")
        
        # Make prediction for Overall AQI
        predictions["Overall_AQI"] = float(overall_model.predict(overall_input_scaled)[0])
        print(f"Predicted Overall_AQI: {predictions['Overall_AQI']:.2f}")

        # Add AQI categories for all predictions
        for aqi_key in list(predictions.keys()):
            category_key = aqi_key.replace("AQI", "Category")
            predictions[category_key] = map_aqi_category(predictions[aqi_key])
            print(f"Mapped {aqi_key} ({predictions[aqi_key]:.2f}) to category: {predictions[category_key]}")
        
        # Add sensor ppm readings to the predictions
        predictions["NH3_ppm"] = nh3_ppm
        predictions["CO_ppm"] = co_ppm
        predictions["O3_ppm"] = o3_ppm
        predictions["CH4_ppm"] = ch4_ppm
        
        # Add timestamp to predictions
        predictions["timestamp"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"Added timestamp: {predictions['timestamp']}")

        print(f"Prediction complete with {len(predictions)} values")
        print(f"========== PREDICTION END ==========\n")
        return predictions
    except Exception as e:
        print(f"ERROR in prediction: {e}")
        raise

# Global variables to store the latest readings and predictions
latest_readings = {}
latest_predictions = {}

# Global variable to store historical data
historical_data = {}
# Global variable to store time series data for graphing
time_series_data = {}
# Global variable to store individual AQI time series data
individual_aqi_time_series = {}

# Function to save historical data to a file
def save_historical_data():
    print(f"Saving historical data to file...")
    try:
        with open("historical_data.json", "w") as f:
            json.dump(historical_data, f)
        print(f"Historical data saved successfully. Contains {sum(len(data) for data in historical_data.values())} records across {len(historical_data)} days")
    except Exception as e:
        print(f"ERROR saving historical data: {e}")

# Function to save time series data to a file
def save_time_series_data():
    print(f"Saving time series data to file...")
    try:
        with open("time_series_data.json", "w") as f:
            json.dump(time_series_data, f)
        print(f"Time series data saved successfully. Contains {sum(len(data) for data in time_series_data.values())} records across {len(time_series_data)} days")
    except Exception as e:
        print(f"ERROR saving time series data: {e}")

# Function to save individual AQI time series data to a file
def save_individual_aqi_time_series():
    print(f"Saving individual AQI time series data to file...")
    try:
        with open("individual_aqi_time_series.json", "w") as f:
            json.dump(individual_aqi_time_series, f)
        print(f"Individual AQI time series data saved successfully. Contains {sum(len(data) for data in individual_aqi_time_series.values())} records across {len(individual_aqi_time_series)} days")
    except Exception as e:
        print(f"ERROR saving individual AQI time series data: {e}")

# Function to load historical data from a file
def load_historical_data():
    global historical_data
    print("Loading historical data...")
    try:
        if os.path.exists("historical_data.json"):
            with open("historical_data.json", "r") as f:
                historical_data = json.load(f)
            print(f"Historical data loaded successfully. Contains {sum(len(data) for data in historical_data.values())} records across {len(historical_data)} days")
        else:
            print("No historical data file found. Starting with empty dataset.")
            historical_data = {}
    except Exception as e:
        print(f"ERROR loading historical data: {e}")
        historical_data = {}

# Function to load time series data from a file
def load_time_series_data():
    global time_series_data
    print("Loading time series data...")
    try:
        if os.path.exists("time_series_data.json"):
            with open("time_series_data.json", "r") as f:
                time_series_data = json.load(f)
            print(f"Time series data loaded successfully. Contains {sum(len(data) for data in time_series_data.values())} records across {len(time_series_data)} days")
        else:
            print("No time series data file found. Starting with empty dataset.")
            time_series_data = {}
    except Exception as e:
        print(f"ERROR loading time series data: {e}")
        time_series_data = {}

# Function to load individual AQI time series data from a file
def load_individual_aqi_time_series():
    global individual_aqi_time_series
    print("Loading individual AQI time series data...")
    try:
        if os.path.exists("individual_aqi_time_series.json"):
            with open("individual_aqi_time_series.json", "r") as f:
                individual_aqi_time_series = json.load(f)
            print(f"Individual AQI time series data loaded successfully. Contains {sum(len(data) for data in individual_aqi_time_series.values())} records across {len(individual_aqi_time_series)} days")
        else:
            print("No individual AQI time series data file found. Starting with empty dataset.")
            individual_aqi_time_series = {}
    except Exception as e:
        print(f"ERROR loading individual AQI time series data: {e}")
        individual_aqi_time_series = {}

# Function to update historical data with full predictions
def update_historical_data(predictions):
    global historical_data
    print("\n========== UPDATING HISTORICAL DATA ==========")
    current_date = datetime.now().strftime("%Y-%m-%d")
    print(f"Updating historical data for date: {current_date}")
    
    if current_date not in historical_data:
        print(f"Creating new entry for date: {current_date}")
        historical_data[current_date] = []
    
    # Add current predictions to today's data
    historical_data[current_date].append(predictions)
    print(f"Added new prediction to {current_date}. Now has {len(historical_data[current_date])} records")
    
    # Keep only the last 7 days of data
    dates = sorted(historical_data.keys())
    if len(dates) > 7:
        for old_date in dates[:-7]:
            print(f"Removing old date from historical data: {old_date}")
            del historical_data[old_date]
    
    print(f"Historical data now contains {len(historical_data)} days")
    save_historical_data()
    print("========== HISTORICAL DATA UPDATED ==========\n")

# Function to update time series data for graphing
def update_time_series_data(predictions):
    global time_series_data
    print("\n========== UPDATING TIME SERIES DATA ==========")
    current_date = datetime.now().strftime("%Y-%m-%d")
    current_time = datetime.now().strftime("%H:%M:%S")
    print(f"Updating time series data for date: {current_date}, time: {current_time}")
    
    if current_date not in time_series_data:
        print(f"Creating new entry for date: {current_date}")
        time_series_data[current_date] = []
    
    # Add only the necessary data for graphing
    time_series_data[current_date].append({
        "time": current_time,
        "Overall_AQI": predictions["Overall_AQI"]
    })
    print(f"Added new time point to {current_date}. Now has {len(time_series_data[current_date])} records")
    
    # Keep only the last 7 days of data
    dates = sorted(time_series_data.keys())
    if len(dates) > 7:
        for old_date in dates[:-7]:
            print(f"Removing old date from time series data: {old_date}")
            del time_series_data[old_date]
    
    print(f"Time series data now contains {len(time_series_data)} days")
    save_time_series_data()
    print("========== TIME SERIES DATA UPDATED ==========\n")

# Function to update individual AQI time series data for graphing
def update_individual_aqi_time_series(predictions):
    global individual_aqi_time_series
    print("\n========== UPDATING INDIVIDUAL AQI TIME SERIES DATA ==========")
    current_date = datetime.now().strftime("%Y-%m-%d")
    current_time = datetime.now().strftime("%H:%M:%S")
    print(f"Updating individual AQI time series data for date: {current_date}, time: {current_time}")
    
    if current_date not in individual_aqi_time_series:
        print(f"Creating new entry for date: {current_date}")
        individual_aqi_time_series[current_date] = []
    
    # Add individual AQI data for graphing
    individual_aqi_time_series[current_date].append({
        "time": current_time,
        "NH3_AQI": predictions["NH3_AQI"],
        "CO_AQI": predictions["CO_AQI"],
        "O3_AQI": predictions["O3_AQI"],
        "CH4_AQI": predictions["CH4_AQI"]
    })
    print(f"Added new individual AQI data point to {current_date}. Now has {len(individual_aqi_time_series[current_date])} records")
    
    # Keep only the last 7 days of data
    dates = sorted(individual_aqi_time_series.keys())
    if len(dates) > 7:
        for old_date in dates[:-7]:
            print(f"Removing old date from individual AQI time series data: {old_date}")
            del individual_aqi_time_series[old_date]
    
    print(f"Individual AQI time series data now contains {len(individual_aqi_time_series)} days")
    save_individual_aqi_time_series()
    print("========== INDIVIDUAL AQI TIME SERIES DATA UPDATED ==========\n")

# Function to read from Arduino and update latest_readings
def read_from_arduino(port="COM3", baud_rate=9600):
    global latest_readings, latest_predictions
    
    print("\n========== STARTING ARDUINO COMMUNICATION ==========")
    print(f"Attempting to connect to Arduino on port {port} at {baud_rate} baud")
    
    # Initialize last prediction time
    last_prediction_time = datetime.now() - timedelta(minutes=1)  # Start immediately
    print(f"Initial prediction time set to: {last_prediction_time}")
    
    try:
        ser = serial.Serial(port, baud_rate, timeout=1)
        print(f"Successfully connected to Arduino on port {port}")
        
        connection_start_time = datetime.now()
        print(f"Connection established at: {connection_start_time}")
        
        while True:
            current_time = datetime.now()
            
            # Check if it's time to make a new prediction (every minute)
            time_since_last = (current_time - last_prediction_time).total_seconds()
            if time_since_last >= 60:
                print(f"\n===== MINUTE INTERVAL REACHED =====")
                print(f"Time since last prediction: {time_since_last:.2f} seconds")
                
                if latest_readings:
                    print(f"Making new prediction at {current_time}")
                    
                    # Make predictions
                    try:
                        predictions = predict_all_aqi(
                            latest_readings.get("NH3", 0),
                            latest_readings.get("CO", 0),
                            latest_readings.get("O3", 0),
                            latest_readings.get("CH4", 0)
                        )
                        
                        # Update latest predictions
                        latest_predictions = predictions
                        print("Latest predictions updated successfully")
                        
                        # Update historical data
                        update_historical_data(predictions)
                        
                        # Update time series data for graphing
                        update_time_series_data(predictions)
                        
                        # Update individual AQI time series data
                        update_individual_aqi_time_series(predictions)
                        
                        # Update last prediction time
                        last_prediction_time = current_time
                        print(f"Updated last prediction time to: {last_prediction_time}")
                    except Exception as e:
                        print(f"ERROR in minute interval processing: {e}")
                else:
                    print("No sensor readings available yet. Skipping prediction.")
            
            # Read from serial port if data is available
            if ser.in_waiting > 0:
                try:
                    data = ser.readline().decode('utf-8').strip()
                    
                    # Only print raw data at the time of prediction
                    if time_since_last >= 60:
                        print(f"\n===== ARDUINO DATA RECEIVED =====")
                        print(f"Raw data: {data}")
                    
                    # Parse the data
                    parts = data.split(',')
                    readings = {}
                    for part in parts:
                        key, value = part.split(':')
                        readings[key] = float(value)
                    
                    # Update the latest readings
                    latest_readings = readings
                    if time_since_last >= 60:
                        print(f"Parsed readings: {json.dumps(latest_readings, indent=2)}")
                        print(f"Updated latest_readings at {datetime.now()}")
                except Exception as e:
                    print(f"ERROR parsing sensor data: {e}")
            
            # Small delay to prevent CPU overuse
            time.sleep(0.1)
    
    except serial.SerialException as e:
        print(f"SERIAL ERROR: {e}")
        print("Will attempt to reconnect in 30 seconds...")
        time.sleep(30)
        print("Restarting Arduino communication thread...")
        threading.Thread(target=read_from_arduino, args=(port, baud_rate), daemon=True).start()
    except KeyboardInterrupt:
        print("\nStopping communication due to keyboard interrupt.")
    except Exception as e:
        print(f"UNEXPECTED ERROR in Arduino communication: {e}")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Serial port closed.")
        print("Arduino communication thread terminated.")

# Start the Arduino reading thread
print("Starting Arduino reading thread...")
threading.Thread(target=read_from_arduino, daemon=True).start()

# API endpoint to get the latest predictions
@app.route('/predict', methods=['GET'])
def predict():
    global latest_predictions
    print(f"\n========== API REQUEST: /predict ==========")
    print(f"Received request at: {datetime.now()}")
    
    if not latest_predictions:
        print("No current predictions available, checking historical data...")
        
        # Try to get the latest prediction from historical data
        fresh_historical_data = {}
        try:
            # Always reload from file to get the latest data
            if os.path.exists("historical_data.json"):
                with open("historical_data.json", "r") as f:
                    fresh_historical_data = json.load(f)
                print(f"Loaded fresh historical data from file")
            
            if fresh_historical_data:
                latest_date = max(fresh_historical_data.keys())
                if fresh_historical_data[latest_date]:
                    latest_historical = fresh_historical_data[latest_date][-1]  # Get the last prediction of the latest day
                    print(f"Found historical prediction from {latest_date}")
                    print(f"Overall AQI: {latest_historical.get('Overall_AQI', 'unknown')}")
                    return jsonify(latest_historical)
        except Exception as e:
            print(f"ERROR loading historical data for prediction: {e}")
        
        print("No predictions available in historical data either.")
        return jsonify({"error": "No predictions available yet"}), 400
    
    print(f"Returning prediction with timestamp: {latest_predictions.get('timestamp', 'unknown')}")
    print(f"Overall AQI: {latest_predictions.get('Overall_AQI', 'unknown')}")
    return jsonify(latest_predictions)

# API endpoint to get historical data for all predictions
@app.route('/history', methods=['GET'])
def history():
    print(f"\n========== API REQUEST: /history ==========")
    print(f"Received request at: {datetime.now()}")
    
    # Always reload historical data from file to get the latest
    fresh_historical_data = {}
    try:
        if os.path.exists("historical_data.json"):
            with open("historical_data.json", "r") as f:
                fresh_historical_data = json.load(f)
            print(f"Loaded fresh historical data from file")
        else:
            print("No historical data file found.")
    except Exception as e:
        print(f"ERROR loading historical data for API: {e}")
        return jsonify({"error": f"Error loading historical data: {str(e)}"}), 500
    
    print(f"Returning historical data for {len(fresh_historical_data)} days")
    for date, data in fresh_historical_data.items():
        print(f"  - {date}: {len(data)} records")
    return jsonify(fresh_historical_data)

# API endpoint to get time series data for graphing
@app.route('/timeseries', methods=['GET'])
def timeseries():
    print(f"\n========== API REQUEST: /timeseries ==========")
    print(f"Received request at: {datetime.now()}")
    
    # Always reload time series data from file to get the latest
    fresh_time_series_data = {}
    try:
        if os.path.exists("time_series_data.json"):
            with open("time_series_data.json", "r") as f:
                fresh_time_series_data = json.load(f)
            print(f"Loaded fresh time series data from file")
        else:
            print("No time series data file found.")
    except Exception as e:
        print(f"ERROR loading time series data for API: {e}")
        return jsonify({"error": f"Error loading time series data: {str(e)}"}), 500
    
    print(f"Returning time series data for {len(fresh_time_series_data)} days")
    for date, data in fresh_time_series_data.items():
        print(f"  - {date}: {len(data)} records")
    return jsonify(fresh_time_series_data)

# API endpoint to get individual AQI time series data
@app.route('/individual_aqi_timeseries', methods=['GET'])
def individual_aqi_timeseries():
    print(f"\n========== API REQUEST: /individual_aqi_timeseries ==========")
    print(f"Received request at: {datetime.now()}")
    
    # Parameter to get specific pollutant data
    pollutant = request.args.get('pollutant', None)
    valid_pollutants = ['NH3_AQI', 'CO_AQI', 'O3_AQI', 'CH4_AQI']
    
    # Always reload individual AQI time series data from file to get the latest
    fresh_individual_aqi_time_series = {}
    try:
        if os.path.exists("individual_aqi_time_series.json"):
            with open("individual_aqi_time_series.json", "r") as f:
                fresh_individual_aqi_time_series = json.load(f)
            print(f"Loaded fresh individual AQI time series data from file")
        else:
            print("No individual AQI time series data file found.")
    except Exception as e:
        print(f"ERROR loading individual AQI time series data for API: {e}")
        return jsonify({"error": f"Error loading individual AQI time series data: {str(e)}"}), 500
    
    # If pollutant is specified, filter data to include only that pollutant
    if pollutant and pollutant in valid_pollutants:
        print(f"Filtering data for specific pollutant: {pollutant}")
        filtered_data = {}
        
        for date, data_points in fresh_individual_aqi_time_series.items():
            filtered_data[date] = []
            for data_point in data_points:
                filtered_data[date].append({
                    "time": data_point["time"],
                    pollutant: data_point[pollutant]
                })
        
        print(f"Returning {pollutant} time series data for {len(filtered_data)} days")
        for date, data in filtered_data.items():
            print(f"  - {date}: {len(data)} records")
        return jsonify(filtered_data)
    
    print(f"Returning all individual AQI time series data for {len(fresh_individual_aqi_time_series)} days")
    for date, data in fresh_individual_aqi_time_series.items():
        print(f"  - {date}: {len(data)} records")
    return jsonify(fresh_individual_aqi_time_series)

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    print(f"\n========== API REQUEST: /health ==========")
    print(f"Health check at: {datetime.now()}")
    
    uptime = datetime.now() - app.config.get('start_time', datetime.now())
    
    # Count the records in the files
    file_data = {
        "historical_file_exists": os.path.exists("historical_data.json"),
        "timeseries_file_exists": os.path.exists("time_series_data.json"),
        "individual_aqi_timeseries_file_exists": os.path.exists("individual_aqi_time_series.json"),
        "historical_days": 0,
        "historical_records": 0,
        "timeseries_days": 0,
        "timeseries_records": 0,
        "individual_aqi_timeseries_days": 0,
        "individual_aqi_timeseries_records": 0
    }
    
    # Check historical data file
    try:
        if file_data["historical_file_exists"]:
            with open("historical_data.json", "r") as f:
                fresh_historical = json.load(f)
                file_data["historical_days"] = len(fresh_historical)
                file_data["historical_records"] = sum(len(data) for data in fresh_historical.values())
    except Exception as e:
        print(f"ERROR checking historical file: {e}")
    
    # Check time series data file
    try:
        if file_data["timeseries_file_exists"]:
            with open("time_series_data.json", "r") as f:
                fresh_timeseries = json.load(f)
                file_data["timeseries_days"] = len(fresh_timeseries)
                file_data["timeseries_records"] = sum(len(data) for data in fresh_timeseries.values())
    except Exception as e:
        print(f"ERROR checking timeseries file: {e}")
    
    # Check individual AQI time series data file
    try:
        if file_data["individual_aqi_timeseries_file_exists"]:
            with open("individual_aqi_time_series.json", "r") as f:
                fresh_individual_aqi = json.load(f)
                file_data["individual_aqi_timeseries_days"] = len(fresh_individual_aqi)
                file_data["individual_aqi_timeseries_records"] = sum(len(data) for data in fresh_individual_aqi.values())
    except Exception as e:
        print(f"ERROR checking individual AQI timeseries file: {e}")
    
    health_data = {
        "status": "ok",
        "uptime_seconds": uptime.total_seconds(),
        "uptime_formatted": str(uptime),
        "has_sensor_readings": len(latest_readings) > 0,
        "has_predictions": len(latest_predictions) > 0,
        "stored_days_in_memory": len(historical_data),
        "file_status": file_data,
        "version": "1.1.0",  # Incremented version to reflect update with individual AQI time series
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    
    print(f"Health data: {json.dumps(health_data, indent=2)}")
    return jsonify(health_data)

if __name__ == "__main__":
    # Set start time for uptime tracking
    app.config['start_time'] = datetime.now()
    print(f"Server start time: {app.config['start_time']}")
    
    # Load historical data
    load_historical_data()
    
    # Load time series data
    load_time_series_data()
    
    # Load individual AQI time series data
    load_individual_aqi_time_series()
    
    print("\n========== STARTING SERVER ==========")
    print(f"Starting Flask server at: {datetime.now()}")
    print("Server will be available at http://0.0.0.0:5000")
    print("Endpoints available:")
    print("  - /predict                 : Get latest prediction")
    print("  - /history                 : Get full historical data")
    print("  - /timeseries              : Get overall AQI time series data for graphing")
    print("  - /individual_aqi_timeseries : Get individual pollutant AQI time series data")
    print("  - /health                  : Check server status")
    app.run(host='0.0.0.0', port=5000, debug=True)