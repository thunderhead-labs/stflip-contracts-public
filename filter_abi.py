import os
import json
import time

working_directory = os.getcwd()
out_folder = os.path.join(working_directory, 'out')

start_time = time.time()
count = 0
count2 = 0
for folder in os.listdir(out_folder):
    for file in os.listdir(os.path.join(out_folder, folder)):
        if file.endswith('.json'):
            abi = json.load(
                open(os.path.join(out_folder,folder,file))
            ).get('abi')
            bytecode = json.load(
                open(os.path.join(out_folder,folder,file))
            ).get('bytecode').get('object')
            
            destination_path = os.path.join(working_directory, 'abi', file)
            with open(destination_path, 'w') as dest_file:
                dest_file.write(json.dumps(abi,indent=2))
                count +=1

            destination_path = os.path.join(working_directory, 'abi', file.replace('.json','.bin'))
            with open(destination_path, 'w') as dest_file:
                dest_file.write(bytecode)
                count2 +=1

        else:
            print(f"Skipping {file}")

print(f"Snatched {count} ABIs and {count} bytecodes in {round(time.time()-start_time,2)}s")
