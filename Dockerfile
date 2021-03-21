FROM openjdk:11

# Temporary workdir
WORKDIR /tmp/minecraft

# currently using version 1.16.1.
ARG papermc_version=1.16.4
ARG papermc_uri=https://papermc.io/api/v1/paper/${papermc_version}/latest/download
ENV PAPERMC_URI=$papermc_uri

# Download Papermac
ADD ${PAPERMC_URI} /tmp/minecraft/papermc.jar

# Patch Papermc to the newest version
RUN /usr/local/openjdk-11/bin/java -jar /tmp/minecraft/papermc.jar; exit 0

# Switch workdir
WORKDIR /opt/minecraft

# Accept the Mojang eula
RUN echo eula=true >> eula.txt

# Adding a service user
RUN useradd -ms /bin/bash minecraft && chown minecraft /opt/minecraft -R

# Move patched Papermc.jar to the workdir /opt/minecraft
RUN mv /tmp/minecraft/cache/patched_1.16.4.jar papermc.jar && rm -rf /tmp/minecraft

# Switch to service user
USER minecraft

# Default Minecraft server port
EXPOSE 25565

# Start the Minecraft server with java flags for better performance and using world-container /worlds
# See https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/ for more
ENTRYPOINT /usr/local/openjdk-11/bin/java -jar \
	-Xms4G \
    -Xmx4G \
	-XX:+UseG1GC \
	-XX:+ParallelRefProcEnabled \
	-XX:MaxGCPauseMillis=200 \
	-XX:+UnlockExperimentalVMOptions \
	-XX:+DisableExplicitGC \
	-XX:+AlwaysPreTouch \
	-XX:G1NewSizePercent=15 \
	-XX:G1MaxNewSizePercent=20 \
	-XX:G1HeapRegionSize=4M \
	-XX:G1ReservePercent=10 \
	-XX:G1HeapWastePercent=5 \
	-XX:G1MixedGCCountTarget=4 \
	-XX:InitiatingHeapOccupancyPercent=8 \
	-XX:G1MixedGCLiveThresholdPercent=90 \
	-XX:G1RSetUpdatingPauseTimePercent=5 \
	-XX:SurvivorRatio=32 \
	-XX:+PerfDisableSharedMem \
	-XX:MaxTenuringThreshold=1 \
	-Dusing.aikars.flags=https://mcflags.emc.gs \
	-Daikars.new.flags=true \
    -Dcom.mojang.eula.agree=true \
    /opt/minecraft/papermc.jar nogui --world-container=worlds
