/* ECE 540 Final Project
 * Made by Alex Beaulier 11/2/2021
 * Developed with Neaman and David
 *
 * Copyright (C) 2021
 * Portland State University, College of Electrical and Computer Engineering, Portland, Oregon.
 *
 * The codes are mainly developed by Alex Beaulier M.S. in ECE.
 *
 * As an open-source 3D LIDAR Scanning project.
 * Translates LIDAR LITE data into a 3D point cloud projected onto a VGA monitor
 * Updates an LCD on progress and also translates 3D points into color depth data for a 3D image. 
 * Scan directions are left, forward and right. Could be upgraded to have 360 degrees using stepper or brushless DC motors.
 * 
 * Contact Info: you can send an email to beaulier@pdx.edu for any problems. 
 *
 * Note: the above information must be kept whenever or wherever the codes are used.
 *
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

//MACROS
#define GPIO_SWs              0x80001400
#define GPIO_LEDs             0x80001404
#define GPIO_INOUT            0x80001408
#define vga_pwm_pitch_reg     0x80003000
#define vga_pwm_yaw_reg       0x80003004
#define vga_pixel_color       0x80003400    //31:0 =>  [0:9] YAW, [10:21] PITCH, [21:25] Color + unused
#define vga_pix_num           0x80003404
#define READ_GPIO(dir) (*(volatile unsigned *)dir)
#define WRITE_GPIO(dir, value) { (*(volatile unsigned *)dir) = (value); }

#define SegEn_ADDR    0x80001038
#define SegDig_ADDR   0x8000103C
#define WRITE_7Seg(dir, value) { (*(volatile unsigned *)dir) = (value); }


//Function List
void directionizer( int pushbutton, int *direction);
void Colorize(int LidarDataint);
void Greyerizer(int yaw, int pitch, float *LidarData, int *CompoundData);


int main ( void )
{
    int En_Value=0xFFFF, switches_value;
    int servovalpitch=0, servovalyaw=0;
    int pushbutton;
    int * pushpointer = 0x80001800;     //Issue using #define with this before, used pointer instead
    int yaw=0, pitch=0, K;
    int direction = 0;
    int CompoundData = 0;
    int pixel_lidar_num = 0;
    float LidarData;
    //int checkval, checkval2;
    //2ms = 180 deg, need 30 degree offsets, start 0 to 120 L, 30 to 150 F or 60 to 180 R, 
    // 200000 / 180 * 30 = 33,333 ticks
    // 200000 / 180 * 60 = 66,666 ticks
    int regwritevalue;
    WRITE_GPIO(GPIO_INOUT, En_Value);

    //*******************************************************
    //Main loop, writes endlessly to change servo duty cycle.
    //*******************************************************
    while (1) { 

        switches_value = READ_GPIO(GPIO_SWs); // Determine which direction

        pushbutton = *pushpointer;

        switches_value = switches_value >> 16;
        WRITE_GPIO(GPIO_LEDs, switches_value);
        WRITE_7Seg(SegDig_ADDR, 6073113);    //start

        //Execute scan only if push has been activated
        if(pushbutton != 0){
            directionizer(pushbutton,&direction);   //Assign the starting angle

            //"Erase" memory if bottom or center button is pushed
            if (pushbutton == 16 || pushbutton == 1) {
                for(pitch=0;pitch<480;pitch++){
                    for(yaw=0;yaw<640;yaw++){
                        WRITE_GPIO(vga_pixel_color, 0000); //DARKEN THE SCREEN
                        pixel_lidar_num = (640*pitch + yaw);
                        WRITE_GPIO(vga_pix_num, pixel_lidar_num);
                        
                    }
                }
            }
        else {
            //*******************************************************
            //PITCH CONTROL LOGIC
            //*******************************************************
            //480 pixels across, 100 degree positioning centered at 50, .5ms to 2.5ms
            //250000 - 50000 = (200000steps per 180 deg) / 180deg * 100deg = 111111steps per 100deg / 480 pixels ~ 231 steps/pixel
            for(pitch=0;pitch<480;pitch+=30){
                
                servovalpitch = READ_GPIO(vga_pwm_pitch_reg);
                regwritevalue = pitch * (111111 / 480);
                WRITE_GPIO(vga_pwm_pitch_reg, 200000 - regwritevalue);
                servovalpitch = READ_GPIO(vga_pwm_pitch_reg);
                for (K=0;K<21000;K++){} //Pause
                WRITE_GPIO(GPIO_LEDs,pow(2,(pitch/30))); //Update LED Scan % from 0 to 100
                pushbutton = *pushpointer;

                if (pushbutton == 16 || pushbutton == 1) {
                    for(pitch=0;pitch<480;pitch++){
                        for(yaw=0;yaw<640;yaw++){
                            WRITE_GPIO(vga_pixel_color, 0000); //DARKEN THE SCREEN
                            pixel_lidar_num = (640*pitch + yaw);
                            WRITE_GPIO(vga_pix_num, pixel_lidar_num);
                            
                        }
                    }
                    break;
                }

                //*******************************************************
                //Yaw CONTROL LOGIC
                //*******************************************************
                //640 pixels across, 120 degree positioning, .5ms to 2.5ms
                //250000 - 50000 = (200000steps per 180 deg) / 180deg * 120deg = 133333steps per 120deg / 640 pixels ~ 208 steps/pixel
                for(yaw=0;yaw<640;yaw++){
                    servovalyaw = READ_GPIO(vga_pwm_yaw_reg);
                    regwritevalue = yaw * (133333 / 640);
                    WRITE_GPIO(vga_pwm_yaw_reg, (direction - regwritevalue));
                    servovalyaw = READ_GPIO(vga_pwm_yaw_reg);
                    for (K=0;K<21000;K++){} //Pause

                    //*******************************************************
                    //LIDAR SCAN INSERT HERE (DAVID)
                    //*******************************************************

                    //LidarDataInt = READ_GPIO(Lidarregister);
                    
                    //*******************************************************
                    //LCD WRITE INSERT HERE (NEAMAN)
                    //*******************************************************
                    WRITE_7Seg(SegDig_ADDR, 176470);     //scan

                    //*******************************************************
                    //COORDINATE Depth Threshold (ALEX)
                    //*******************************************************
                    //Colorize(LidarDataint);
                    LidarData = rand() % (40); //Turnoff later, this is for testing VGA writes.
                    Greyerizer(yaw, pitch, &LidarData, &CompoundData); //Converts color and sends out to the vga reg
                    //COORDINATE TO ARRAY REGISTER/COE IMAGE HERE (ALEX)
                    WRITE_GPIO(vga_pixel_color, CompoundData); // [9:0] Yaw, [20:10] Pitch, [27:24] Color
                    pixel_lidar_num = (640*pitch + yaw);
                    WRITE_GPIO(vga_pix_num, pixel_lidar_num);

                }//EO YAW Loop
                WRITE_GPIO(vga_pwm_yaw_reg, direction); //Reset to 0 since this takes longer
                for (K=0;K<153000;K++){} //Pause

            }//EO Pitch Loop
        }//EO PB Check
        }//EO PB If
        
    }//EO Infinite While
    return(0);
}




//*******************************************************
//Functions
//*******************************************************
//Reports back an offset based on a button press
void directionizer(int pushbutton, int *direction){
        //SCAN Direction Pushbutton
        switch(pushbutton){
            //LEFT
            case 4  :
            *direction = 250000;
            break;

            //FORWARD
            case 2  :
            *direction = 222000;
            break;

            //RIGHT
            case 8  :
            *direction = 183333;
            break;

            //DOWN //Not used
            case 16  :
            break;
            
            //MIDDLE //Not Used
            case 1  :
            break;
            default: ;//Destroy latches
        }
}//EO Directionizer


//Function LIDAR DEPTH Greyerizer
//Colors a pixel in grayscale based on depth. 
//Reports back the pixel color with pitch and yaw within an integer
//Close Depth : White [15]
//Far Depth   : Black [0]
void Greyerizer(int pitch, int yaw, float *LidarData, int *CompoundData){
        int checkval;
        checkval = (1-(*LidarData/40))*15;
        checkval = round((1-(*LidarData/40))*15);
        checkval = checkval << 19;
        checkval = checkval + (pitch << 10);
        checkval = checkval + (yaw);
        //*CompoundData = ((int) (round((1-(*LidarData/40)))*15)) + (pitch << 14) + (yaw<<4);
        *CompoundData = (int) round((1-(*LidarData/40))*15);
        return (0);
}//EO greyerizer

//Function LIDAR DEPTH Colorizer
//Colors a pixel in RGB based on depth. 
//Reports back the pixel color with pitch and yaw within an integer
//Close Depth : TBD
//Far Depth   : TBD
void Colorize(int LidarDataint){
        switch(LidarDataint){
            
            //Close Depth : RED
            case 0 ... 13  :
            WRITE_GPIO(vga_pixel_color, LidarDataint);
            break;

            //Mid Depth : Green
            case 14 ... 26   :
            WRITE_GPIO(vga_pixel_color, LidarDataint << 4 );
            break;

            //Far Depth : Blue
            case 27 ... 40  :
            WRITE_GPIO(vga_pixel_color, LidarDataint << 8);
            break;

            default: ;//Destroy latches
        }
}//EO Colorize