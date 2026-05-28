import numpy as np
import cv2
from cv2 import dnn

def main():
   
    input_image_path = "colorized_parsed_video/frame99999.jpg"
    images = [input_image_path]
    colorize(images)
  

def colorize(images): 
    #--------Model file paths--------#
    prototxt_file = 'model/colorization_deploy_v2.prototxt'
    model_file = 'model/colorization_release_v2.caffemodel'
    hull_pts = 'model/pts_in_hull.npy'
    
    #--------Reading the model params--------#
    net = dnn.readNetFromCaffe(prototxt_file, model_file)
    kernel = np.load(hull_pts)
   
    count = 100000
    for i in images:
        img = cv2.imread(i)
        if img is None:
            print(f"Error: Could not read image {i}")
            continue
        scaled = img.astype("float32") / 255.0
        lab_img = cv2.cvtColor(scaled, cv2.COLOR_BGR2LAB)
        
        # add the cluster centers as 1x1 convolutions to the model
        class8 = net.getLayerId("class8_ab")
        conv8 = net.getLayerId("conv8_313_rh")
        pts = kernel.transpose().reshape(2, 313, 1, 1)
        net.getLayer(class8).blobs = [pts.astype("float32")]
        net.getLayer(conv8).blobs = [np.full([1, 313], 2.606, dtype="float32")]
        
        # resize the image for the network
        resized = cv2.resize(lab_img, (224, 224))
        # split the L channel
        L = cv2.split(resized)[0]
        # mean subtraction (hyperparameter)
        L -= 50

        # predicting the ab channels from the input L channel
        net.setInput(cv2.dnn.blobFromImage(L))
        ab_channel = net.forward()[0, :, :, :].transpose((1, 2, 0))
        # resize the predicted 'ab' volume to the same dimensions as input image
        ab_channel = cv2.resize(ab_channel, (img.shape[1], img.shape[0]))
        
        # Take the L channel from the image
        L = cv2.split(lab_img)[0]
        # Join the L channel with predicted ab channel
        colorized = np.concatenate((L[:, :, np.newaxis], ab_channel), axis=2)
        
        # Convert from Lab to BGR
        colorized = cv2.cvtColor(colorized, cv2.COLOR_LAB2BGR)
        colorized = np.clip(colorized, 0, 1)
        
        # Convert to 0-255 uint8
        colorized = (255 * colorized).astype("uint8")
        
        # Resize for display/save
        colorized = cv2.resize(colorized, (640, 640))
        file = "colorized_parsed_video/frame%d.jpg" % count
        print(f"Saving {file}")
        cv2.imwrite(file, colorized)
        count += 1

if __name__ == "__main__":
    main()