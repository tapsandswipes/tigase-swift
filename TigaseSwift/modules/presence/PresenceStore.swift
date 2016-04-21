//
// PresenceStore.swift
//
// TigaseSwift
// Copyright (C) 2016 "Tigase, Inc." <office@tigase.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. Look for COPYING file in the top folder.
// If not, see http://www.gnu.org/licenses/.
//

import Foundation

public class PresenceStore {
    
    private var handler:PresenceStoreHandler?;
    
    private var bestPresence = [BareJID:Presence]();
    private var presenceByJid = [JID:Presence]();
    private var presencesMapByBareJid = [BareJID:[String:Presence]]();
    
    public func clear() {
        presenceByJid.removeAll();
        let toNotify = Array(bestPresence.values);
        bestPresence.removeAll();
        toNotify.forEach { (p) in
            handler?.onOffline(p);
        }
        presencesMapByBareJid.removeAll();
    }
    
    public func getBestPresence(jid:BareJID) -> Presence? {
        return bestPresence[jid];
    }
    
    public func getPresence(jid:JID) -> Presence? {
        return presenceByJid[jid];
    }
    
    public func getPresences(jid:BareJID) -> [String:Presence]? {
        return presencesMapByBareJid[jid];
    }
    
    private func findBestPresence(jid:BareJID) -> Presence? {
        var result:Presence? = nil;
        presencesMapByBareJid[jid]?.values.forEach({ (p) in
            if (result == nil || (p.priority >= result!.priority && p.type == nil)) {
                result = p;
            }
        })
        return result;
    }
    
    public func isAvailable(jid:BareJID) -> Bool {
        return presencesMapByBareJid[jid]?.values.indexOf({ (p) -> Bool in
            return p.type == nil || p.type == StanzaType.available;
        }) != nil;
    }
    
    public func setHandler(handler:PresenceStoreHandler) {
        self.handler = handler;
    }
    
    public func setPresence(show:Presence.Show, status:String?, priority:Int?) {
        self.handler?.setPresence(show, status: status, priority: priority);
    }
    
    func update(presence:Presence) -> Bool {
        if let from = presence.from {
            var wasAwailable = self.isAvailable(from.bareJid);
            presenceByJid[from] = presence;
            var byResource = presencesMapByBareJid[from.bareJid] ?? [String:Presence]();
            byResource[from.resource ?? ""] = presence;
            presencesMapByBareJid[from.bareJid] = byResource;
            updateBestPresence(from.bareJid);
            var isAvailable = self.isAvailable(from.bareJid);
            return wasAwailable != isAvailable;
        }
        return false;
    }
    
    func updateBestPresence(from:BareJID) {
        if let best = findBestPresence(from) {
            bestPresence[from] = best;
        }
    }
}

public protocol PresenceStoreHandler {
    
    func onOffline(presence:Presence);
    
    func setPresence(show:Presence.Show, status:String?, priority:Int?);
}