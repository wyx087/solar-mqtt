
/**
 * @file
 * A simple subscriber program that performs automatic reconnections.
 */
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

#include <time.h>
#include <string.h>


#include <mqtt.h>
#include "templates/posix_sockets.h"

/****** Adjustable variables **************/
#define AVGOVER 3
#define SHUTDOWNCOUNT 10
#define ONTIMEOUT 999 // After how long turn off everything to redetermine state 

#define GPUpwrMAX 160
#define GPUpwrMIN 128

const char defaultlogfilename[] = "/mnt/h/Temp/solar.log";
//const char defaultlogfilename[] = "/mnt/ramdisk/solar.log";
//const char defaultgraphname[] = "/mnt/ramdisk/solar_graph.log";
char logfilename[100];
int EN_SHUTDOWN = 1;  // set to 0 to disable shutdown
int EN_STOPMINING = 1;  // set to 0 to disable stop mining
int statusMining = 0;  // Mining status, set initially in main, later used and changed in publish_callback 
int countShutdown = SHUTDOWNCOUNT;  // Slows down Shutdown so can have time to close program 
/*******************************************/


/**
 * @brief A structure that I will use to keep track of some data needed 
 *        to setup the connection to the broker.
 * 
 * An instance of this struct will be created in my \c main(). Then, whenever
 * \ref reconnect_client is called, this instance will be passed. 
 */
struct reconnect_state_t {
    const char* hostname;
    const char* port;
    const char* topic;
    uint8_t* sendbuf;
    size_t sendbufsz;
    uint8_t* recvbuf;
    size_t recvbufsz;
};


/**
 * @brief My reconnect callback. It will reestablish the connection whenever 
 *        an error occurs. 
 */
void reconnect_client(struct mqtt_client* client, void **reconnect_state_vptr);

/**
 * @brief The function will be called whenever a PUBLISH message is received.
 */
void publish_callback(void** unused, struct mqtt_response_publish *published);

/**
 * @brief The client's refresher. This function triggers back-end routines to 
 *        handle ingress/egress traffic to the broker.
 * 
 * @note All this function needs to do is call \ref __mqtt_recv and 
 *       \ref __mqtt_send every so often. I've picked 100 ms meaning that 
 *       client ingress/egress traffic will be handled every 100 ms.
 */
void* client_refresher(void* client);

/**
 * @brief Safelty closes the \p sockfd and cancels the \p client_daemon before \c exit. 
 */
void exit_example(int status, int sockfd, pthread_t *client_daemon);


int main(int argc, const char *argv[]) 
{
    const char* addr;
    const char* port;
    const char* topic;

    // vvvvvv -- WYXadded -- vvvvvv 
    strncpy(logfilename, defaultlogfilename, sizeof(defaultlogfilename));
    if (argc > 1) {  // Determine if we will shutdown computer (default yes) 
        EN_SHUTDOWN = atoi(argv[1]);
    } 
    if (argc > 2) {  // Whether we will stop mining (default yes) 
        EN_STOPMINING = atoi(argv[2]);
    } 
    if (argc > 3) {  // Is it currently mining? (default no) 
        statusMining = atoi(argv[3]);
    }
    if (argc > 4) {  // Slows down Shutdown so can have time to close program 
        countShutdown = atoi(argv[4]);
    }
    
    if (EN_SHUTDOWN == 1) {
        printf("\n   **  ******** Attention! ******** ** \n\n"); 
        printf("   **  This program will shutdown the computer! **  \n");
    } 
    printf("\n   **  CTRL-C to close this program and use the computer normally ** \n"); 
    printf("\n   **  ******** Attention! ******** ** \n\n"); 
    
    printf("\n Shutdown setting:-  %d   ", EN_SHUTDOWN);
    printf("\n Stop mining setting:-  %d   ", EN_STOPMINING);
    printf("\n Mining status:-  %d   ", statusMining);
    printf("\n First Shutdown delay:-  %d   ", countShutdown);
    printf("\n");
    printf("\nWriting to log file:- %s \n", logfilename);
    printf("Format:- time | statusMining | countShutdown | valUsage | valGenerating | valExporting");
    printf("\n");
    // ^^^^^^ -- WYXadded -- ^^^^^^  
    
    
    // /* get address (argv[1] if present) */
    // if (argc > 1) {
    //     addr = argv[1];
    // } else {
         addr = "192.168.5.5";
    // }
    // 
    // /* get port number (argv[2] if present) */
    // if (argc > 2) {
    //     port = argv[2];
    // } else {
         port = "1883";
    // }
    // 
    // /* get the topic name to publish */
    // if (argc > 3) {
    //     topic = argv[3];
    // } else {
         topic = "power/#";
    // }

    /* build the reconnect_state structure which will be passed to reconnect */
    struct reconnect_state_t reconnect_state;
    reconnect_state.hostname = addr;
    reconnect_state.port = port;
    reconnect_state.topic = topic;
    uint8_t sendbuf[2048];
    uint8_t recvbuf[1024];
    reconnect_state.sendbuf = sendbuf;
    reconnect_state.sendbufsz = sizeof(sendbuf);
    reconnect_state.recvbuf = recvbuf;
    reconnect_state.recvbufsz = sizeof(recvbuf);

    /* setup a client */
    struct mqtt_client client;

    mqtt_init_reconnect(&client, 
                        reconnect_client, &reconnect_state, 
                        publish_callback
    );

    /* start a thread to refresh the client (handle egress and ingree client traffic) */
    pthread_t client_daemon;
    if(pthread_create(&client_daemon, NULL, client_refresher, &client)) {
        fprintf(stderr, "Failed to start client daemon.\n");
        exit_example(EXIT_FAILURE, -1, NULL);

    }

    /* start publishing the time */
    printf("%s listening for '%s' messages.\n\n", argv[0], topic);
    //printf("Press ENTER to inject an error.\n");
    //printf("Press CTRL-D to exit.\n\n");
    
    /* block */
    while(1) {
    //while(fgetc(stdin) != EOF) {
    //    printf("Injecting error: \"MQTT_ERROR_SOCKET_ERROR\"\n");
    //    client.error = MQTT_ERROR_SOCKET_ERROR;
      sleep (60);
    } 
    
    /* disconnect */
    printf("\n%s disconnecting from %s\n", argv[0], addr);
    sleep(1);

    /* exit */ 
    exit_example(EXIT_SUCCESS, client.socketfd, &client_daemon);
}

void reconnect_client(struct mqtt_client* client, void **reconnect_state_vptr)
{
    struct reconnect_state_t *reconnect_state = *((struct reconnect_state_t**) reconnect_state_vptr);

    /* Close the clients socket if this isn't the initial reconnect call */
    if (client->error != MQTT_ERROR_INITIAL_RECONNECT) {
        close(client->socketfd);
    }

    /* Perform error handling here. */
    if (client->error != MQTT_ERROR_INITIAL_RECONNECT) {
        printf("reconnect_client: called while client was in error state \"%s\"\n", 
               mqtt_error_str(client->error)
        );
    }

    /* Open a new socket. */
    int sockfd = open_nb_socket(reconnect_state->hostname, reconnect_state->port);
    if (sockfd == -1) {
        perror("Failed to open socket: ");
        exit_example(EXIT_FAILURE, sockfd, NULL);
    }

    /* Reinitialize the client. */
    mqtt_reinit(client, sockfd, 
                reconnect_state->sendbuf, reconnect_state->sendbufsz,
                reconnect_state->recvbuf, reconnect_state->recvbufsz
    );

    /* Create an anonymous session */
    const char* client_id = NULL;
    /* Ensure we have a clean session */
    uint8_t connect_flags = MQTT_CONNECT_CLEAN_SESSION;
    /* Send connection request to the broker. */
    mqtt_connect(client, client_id, NULL, NULL, 0, NULL, NULL, connect_flags, 400);

    /* Subscribe to the topic. */
    mqtt_subscribe(client, reconnect_state->topic, 0);
}

void exit_example(int status, int sockfd, pthread_t *client_daemon)
{
    if (sockfd != -1) close(sockfd);
    if (client_daemon != NULL) pthread_cancel(*client_daemon);
    exit(status);
}

void publish_callback(void** unused, struct mqtt_response_publish *published) 
{
    // vvvvvv -- WYXadded -- vvvvvv 
    static int receivedflag =0;
    char msgbuf[1000];
    char header [50];
    char payload [50];
    static signed long valUsage =0, valGenerating =0, valExporting =0, valImporting =0;
    static signed long avgUsage =0, avgGenerating =0, avgExporting =0;
    static signed long sumUsage =0, sumGenerating =0, sumExporting =0;
    static signed long aryUsage[AVGOVER] ={0}, aryGenerating[AVGOVER] ={0}, aryExporting[AVGOVER] ={0};
    static int countUsage =0, countGenerating =0, countExporting =0;
    static int statusSocket =0, countON =0;
    static int GPUpwr_applied = 150, GPUpwr_new = 0, MiningStopDelay = AVGOVER;
    char command[200];
    
    FILE * pLogFile = NULL;
    FILE * pGraphFile = NULL;
    time_t rawtime;
    char timestr[30];
    // ^^^^^^ -- WYXadded -- ^^^^^^  
    
    
    /* note that published->topic_name is NOT null-terminated (here we'll change it to a c-string) */
    char* topic_name = (char*) malloc(published->topic_name_size + 1);
    memcpy(topic_name, published->topic_name, published->topic_name_size);
    topic_name[published->topic_name_size] = '\0';

    //printf("Received publish('%s'): %s\n", topic_name, (const char*) published->application_message);
    
    
    // vvvvvv -- WYXadded -- vvvvvv 
    sprintf(header, "%s", topic_name);
    sprintf(payload, "%.*s", published->application_message_size, (const char*) published->application_message);
    //printf("Received publish('%s'): '%s'\n", header, payload);
    
    switch (header[6])
    {
    case 'e': // solar exporting 
      valExporting = strtol(payload, NULL, 10);  // Convert the number to long 
      receivedflag++;
      //printf("Integer valExporting is %ld  \n", valExporting); 
      break;
    case 's': // solar generating 
      valGenerating = strtol(payload, NULL, 10);  // Convert the number to long
      receivedflag++; 
      //printf("Integer valGenerating is %ld  \n", valGenerating); 
      break;
    case 'u': // electricity usage 
      valUsage = strtol(payload, NULL, 10);  // Convert the number to long 
      receivedflag++;
      //printf("Integer valUsage is %ld  \n", valUsage); 
      break;
    }
    
    
    if (receivedflag == 3)  // below only run once for every set of data 
    {
      printf ("\n");
      receivedflag = 0;
    
      // Get time for later log files         
      time (&rawtime);
      strftime(timestr, 30, "%Y/%m/%d %H:%M:%S", localtime(&rawtime)); // generate desired time format 
      
      // Averaging and graph log output: 
      sumExporting = sumExporting + valExporting - aryExporting[countExporting]; 
      aryExporting[countExporting] = valExporting; 
      if (countExporting < AVGOVER -1) countExporting++; else countExporting = 0;
      avgExporting = sumExporting / AVGOVER;
      // printf("--- avg counters:  %d | %d | %d ---\n", countUsage, countExporting, countGenerating);
        // vvvvv  Additional logic here for PC  vvvvvvvvvvvv
        valImporting = valUsage - valGenerating;
        if (EN_SHUTDOWN == 1) printf (" ^^ SHUTDOWN enabled! ^^");
        printf("  **  CTRL-C to close this program and the miner ** \n"); 
        
        if (statusMining == 0) {  // Not mining 
            if (valExporting > GPUpwrMIN + 10) {
                // start mining 
                statusMining = 1; 
                countShutdown = SHUTDOWNCOUNT; 
                system("/mnt/c/Windows/system32/shutdown.exe -a 2> null"); 
                system("/mnt/c/Users/wyx/AppData/Local/Programs/NiceHash\\ Miner/NiceHashMiner.exe &");
                GPUpwr_new = valExporting - 20; 
                if (GPUpwr_new < GPUpwrMAX) { // set GPU power 
                    GPUpwr_applied = GPUpwr_new; 
                    sprintf(command, "'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=%d &", GPUpwr_applied);
                    system(command);
                } else  {             // set GPU to max
                    GPUpwr_applied = GPUpwrMAX;
                    sprintf(command, "'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=%d &", GPUpwr_applied);
                    system(command);
                }
            } else if (valExporting > 20) {
              countShutdown = SHUTDOWNCOUNT; 
              system("/mnt/c/Windows/system32/shutdown.exe -a 2> null"); 
            } else if (valImporting > 20) {
                countShutdown = countShutdown - 1;
                // plan to shutdown 
                if (countShutdown < 1) {
                    if (EN_SHUTDOWN == 1) system("/mnt/c/Windows/system32/shutdown.exe -s -hybrid -t 300"); 
                } 
            }
        } else {   // during mining 
            if (valExporting > 10) {
                MiningStopDelay = AVGOVER;
                countShutdown = SHUTDOWNCOUNT; 
                GPUpwr_new = GPUpwr_applied + valExporting - 3; 
                if (GPUpwr_new < GPUpwrMAX) { // set GPU power 
                    GPUpwr_applied = GPUpwr_new; 
                    sprintf(command, "'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=%d &", GPUpwr_applied);
                    system(command);
                } else  {             // set GPU to max  
                    if (GPUpwr_applied != GPUpwrMAX ) {
                        GPUpwr_applied = GPUpwrMAX; 
                        sprintf(command, "'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=%d &", GPUpwr_applied);
                        system(command);
                    }
                }
            } else if (valImporting > 10) {
                GPUpwr_new = GPUpwr_applied - valImporting - 2; 
                if (GPUpwr_new >= GPUpwrMIN) { // set GPU power 
                    GPUpwr_applied = GPUpwr_new; 
                    sprintf(command, "'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=%d &", GPUpwr_applied);
                    system(command);
                } else {             // stop mining, set GPU to 260 
                    if ((EN_STOPMINING == 1) && (GPUpwr_new < GPUpwrMIN - 40)) {
                        if (valImporting > 800) {
                            statusMining = 0;
                            system("/mnt/c/Windows/system32/taskkill.exe /T /IM NiceHashMiner.exe");
                            system("'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=260 &");
                            if (EN_SHUTDOWN == 1) system("/mnt/c/Windows/system32/shutdown.exe -s -hybrid -t 300"); 
                        } else if (MiningStopDelay < 1) {
                            MiningStopDelay = AVGOVER;
                            statusMining = 0;
                            system("/mnt/c/Windows/system32/taskkill.exe /T /IM NiceHashMiner.exe");
                            system("'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=260 &");
                        } else {
                            MiningStopDelay = MiningStopDelay - 1;
                            printf("Stop mining delayed, cycles left: %d \n", MiningStopDelay);
                            GPUpwr_applied = GPUpwrMIN - 1; 
                            sprintf(command, "'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=%d &", GPUpwr_applied);
                            system(command);
                        }
                    } else {
                        GPUpwr_applied = 104; 
                        sprintf(command, "'/mnt/c/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe' --power-limit=%d &", GPUpwr_applied);
                        system(command);
                    }
                }
            }
        }
        // ^^^^^  Additional logic here for PC  vvvvvvvvvvvv
      
      // Log file for graph 
      
      // Log current status 
      pLogFile = fopen(logfilename, "a"); // append the information into a file 
      if (pLogFile == NULL){
          printf("---ERROR--------file open failed--------ERROR---\n");
          fflush(stdout); // print everything in the stdout buffer
          // exit(1);
      } else {
          sprintf(msgbuf, "%s | %d | %d | %4lu | %4lu | %4lu \n", timestr, statusMining, countShutdown, valUsage, valGenerating, valExporting);
          fprintf(pLogFile, "%s", msgbuf);
          printf("Written to log file:----> %s", msgbuf);
          fclose(pLogFile);
      }
      
      fflush(stdout); // print everything in the stdout buffer
    
    }
    
    
    // ^^^^^^ -- WYXadded -- ^^^^^^  


    free(topic_name);
}

void* client_refresher(void* client)
{
    while(1) 
    {
        mqtt_sync((struct mqtt_client*) client);
        usleep(100000U);
    }
    return NULL;
}
