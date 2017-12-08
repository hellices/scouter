package scouter.agent.counter.jmx;

import scouter.agent.ObjTypeDetector;
import scouter.util.SystemUtil;

import javax.management.MBeanServer;
import javax.management.ObjectName;
import java.lang.management.ManagementFactory;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import static scouter.lang.counters.CounterConstants.*;

/**
 *  refer to glowroot (https://github.com/glowroot/glowroot)
 **/
public class LazyPlatformMBeanServer {

    private static volatile LazyPlatformMBeanServer instance;
    private MBeanServer platformMBeanServer;

    private final boolean waitForContainerToCreatePlatformMBeanServer;

    Map<String, ObjectName> objectNameMap = new HashMap<String, ObjectName>();
    Set<String> ignoreSet = new HashSet<String>();

    public synchronized static LazyPlatformMBeanServer create() {
        if (instance == null) {
            instance = new LazyPlatformMBeanServer();
        }
        return instance;
    }

    private LazyPlatformMBeanServer() {
        waitForContainerToCreatePlatformMBeanServer = JBOSS.equals(ObjTypeDetector.objType)
                || WEBLOGIC.equals(ObjTypeDetector.objType) || WEBSPHERE.equals(ObjTypeDetector.objType);
    }

    public boolean checkInit() throws Exception {
        if (platformMBeanServer != null) return true;
        if (waitForContainerToCreatePlatformMBeanServer) {
            String platformMBeanServerFieldName = SystemUtil.IS_JAVA_IBM ? "platformServer" : "platformMBeanServer";
            Field platformMBeanServerField =
                    ManagementFactory.class.getDeclaredField(platformMBeanServerFieldName);
            platformMBeanServerField.setAccessible(true);
            if (platformMBeanServerField.get(null) != null) {
                platformMBeanServer = ManagementFactory.getPlatformMBeanServer();
                registerHotspotMbean(platformMBeanServer);
                return true;
            }
        } else {
            platformMBeanServer = ManagementFactory.getPlatformMBeanServer();
            registerHotspotMbean(platformMBeanServer);
            return true;
        }
        return false;
    }

    private void registerHotspotMbean(MBeanServer mbeanServer) throws Exception {
        Class<?> sunManagementFactoryHelperClass =
                Class.forName("sun.management.ManagementFactoryHelper");
        Method registerInternalMBeansMethod = sunManagementFactoryHelperClass
                .getDeclaredMethod("registerInternalMBeans", MBeanServer.class);
        registerInternalMBeansMethod.setAccessible(true);
        registerInternalMBeansMethod.invoke(null, mbeanServer);
    }

    public float getValue(String mbean, String attribute) throws Exception {
        if (!checkInit()) return -1;
        if (ignoreSet.contains(mbean)) return -1;
        if (ignoreSet.contains(mbean + attribute)) return -1;
        ObjectName objectName = objectNameMap.get(mbean);
        if (objectName == null) {
            objectName = ObjectName.getInstance(mbean);
            if (objectName.isPattern()) {
                ignoreSet.add(mbean);
                return -1;
            }
            objectNameMap.put(mbean, objectName);
        }
        try {
            Object value = platformMBeanServer.getAttribute(objectName, attribute);
            if (value instanceof Number) {
                return ((Number) value).floatValue();
            } else {
                ignoreSet.add(mbean + attribute);
            }
        } catch (Exception e) {
            ignoreSet.add(mbean + attribute);
        }
        return -1;
    }
}
