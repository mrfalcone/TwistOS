#ifndef _HARDWAREINTERFACE_H_
#define _HARDWAREINTERFACE_H_


#define MAX_DEVICES		1024


class HardwareObject;



class HardwareInterface{

public:
	HardwareInterface();
	
	
private:
	
	
	void AddDevice(HardwareObject *device);
	
	
	HardwareObject *mHWArray[MAX_DEVICES];

};


#endif // _HARDWAREINTERFACE_H_
