import serial
import time
import pandas as pd
import os
import keyboard  # For keyboard shortcuts

# pip install keyboard


# Serial port setup
SERIAL_PORT = '/dev/cu.usbserial-11220'  # Update with your Arduino's port
BAUD_RATE = 9600

# File to save dataset
DATASET_FILE = 'air_quality_dataset_with_methane.csv'

# AQI breakpoints for gases
BREAKPOINTS = {
    'NH3': [
        (0, 50, 0, 10),    # Example breakpoints
        (51, 100, 10, 20),
    ],
    'CO': [
        (0, 50, 0, 4.4),
        (51, 100, 4.5, 9.4),
    ],
    'O3': [
        (0, 50, 0, 0.054),
        (51, 100, 0.055, 0.07),
    ],
}

def calculate_aqi(concentration, pollutant):
    """
    Calculate AQI for a given pollutant and concentration using defined breakpoints.
    """
    if pollutant not in BREAKPOINTS:
        return -1  # Return -1 if breakpoints are not defined for the pollutant

    for bp in BREAKPOINTS[pollutant]:
        il, ih, cl, ch = bp
        if cl <= concentration <= ch:
            return ((ih - il) / (ch - cl)) * (concentration - cl) + il
    return -1  # Invalid concentration

def save_to_csv(data, file):
    """
    Save a row of data to the CSV file.
    Continuously updates the file by appending data.
    """
    if not os.path.exists(file):
        # Create a new file with headers
        pd.DataFrame([data]).to_csv(file, index=False)
    else:
        # Append to the existing file
        pd.DataFrame([data]).to_csv(file, mode='a', header=False, index=False)

def main():
    """
    Main function to read data from the Arduino and save it to a CSV file.
    Includes keyboard shortcuts for controlling data collection.
    """
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    time.sleep(2)  # Allow Serial to initialize

    print("Collecting data... Use shortcuts to control:")
    print("  - Press 'p' to pause.")
    print("  - Press 'r' to resume.")
    print("  - Press 'l' to change location.")
    print("  - Press 'Ctrl+C' to stop.")

    location = input("Enter the initial location: ")
    paused = False

    while True:
        try:
            if not paused:
                line = ser.readline().decode('utf-8').strip()
                if line:
                    # Parse data
                    data = {kv.split(':')[0]: float(kv.split(':')[1]) for kv in line.split(',')}
                    nh3_aqi = calculate_aqi(data['NH3'], 'NH3')
                    co_aqi = calculate_aqi(data['CO'], 'CO')
                    o3_aqi = calculate_aqi(data['O3'], 'O3')

                    # Methane (CH4) does not have an AQI calculation here
                    ch4_ppm = data.get('CH4', 0.0)  # Default to 0.0 if CH4 is missing

                    # Overall AQI
                    overall_aqi = max(nh3_aqi, co_aqi, o3_aqi)

                    # Prepare a row for the dataset
                    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
                    row = {
                        'Timestamp': timestamp,
                        'Location': location,
                        'NH3_ppm': data['NH3'],
                        'CO_ppm': data['CO'],
                        'O3_ppm': data['O3'],
                        'CH4_ppm': ch4_ppm,
                        'NH3_AQI': nh3_aqi,
                        'CO_AQI': co_aqi,
                        'O3_AQI': o3_aqi,
                        'Overall_AQI': overall_aqi
                    }

                    # Save the row to the CSV file
                    save_to_csv(row, DATASET_FILE)
                    print(f"Data saved: {row}")

            # Handle keyboard shortcuts
            if keyboard.is_pressed('p'):
                if not paused:
                    paused = True
                    print("Data collection paused.")
                    time.sleep(1)  # Prevent rapid toggling

            if keyboard.is_pressed('r'):
                if paused:
                    paused = False
                    print("Data collection resumed.")
                    time.sleep(1)  # Prevent rapid toggling

            if keyboard.is_pressed('l'):
                location = input("Enter new location: ")
                print(f"Location updated to {location}.")
                time.sleep(1)  # Prevent rapid toggling

        except KeyboardInterrupt:
            print("Exiting...")
            break
        except Exception as e:
            print(f"Error: {e}")

if __name__ == '__main__':
    main()
